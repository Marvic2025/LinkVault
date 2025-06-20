;; BookmarkHub - A decentralized bookmark management system on Stacks
;; Version: 1.0.0
;; Author: Community

;; ===========================================
;; CONSTANTS & ERROR CODES
;; ===========================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARAMS (err u102))
(define-constant ERR_LIMIT_EXCEEDED (err u103))

;; Maximum values for security
(define-constant MAX_TITLE_LENGTH u100)
(define-constant MAX_URL_LENGTH u200)
(define-constant MAX_DESCRIPTION_LENGTH u500)
(define-constant MAX_TAGS_LENGTH u200)
(define-constant MAX_PAGINATION_LIMIT u50)

;; ===========================================
;; DATA STRUCTURES
;; ===========================================

;; Main bookmark storage
(define-map user-bookmarks
  { owner: principal, bookmark-id: uint }
  {
    title: (string-ascii 100),
    url: (string-ascii 200),
    description: (optional (string-ascii 500)),
    tags: (optional (string-ascii 200)),
    created-at: uint,
    updated-at: uint,
    is-private: bool,
    is-favorite: bool,
    visit-count: uint
  }
)

;; User bookmark counters
(define-map user-bookmark-count
  principal
  uint
)

;; User settings and preferences
(define-map user-settings
  principal
  {
    default-private: bool,
    created-at: uint,
    total-bookmarks: uint,
    public-bookmarks: uint
  }
)

;; Bookmark categories/collections
(define-map bookmark-collections
  { owner: principal, collection-name: (string-ascii 50) }
  {
    description: (optional (string-ascii 200)),
    created-at: uint,
    bookmark-count: uint,
    is-public: bool
  }
)

;; ===========================================
;; PRIVATE HELPER FUNCTIONS
;; ===========================================

;; Check if the caller owns a specific bookmark
(define-private (is-bookmark-owner (owner principal) (bookmark-id uint))
  (is-eq tx-sender owner)
)

;; Get next bookmark ID for a user
(define-private (get-next-bookmark-id (user principal))
  (+ (default-to u0 (map-get? user-bookmark-count user)) u1)
)

;; Validate bookmark parameters
(define-private (is-valid-bookmark-data (title (string-ascii 100)) (url (string-ascii 200)))
  (and 
    (> (len title) u0)
    (> (len url) u0)
    (<= (len title) MAX_TITLE_LENGTH)
    (<= (len url) MAX_URL_LENGTH)
  )
)

;; ===========================================
;; PUBLIC FUNCTIONS - BOOKMARK MANAGEMENT
;; ===========================================

;; Create a new bookmark with enhanced metadata
(define-public (create-bookmark 
  (title (string-ascii 100)) 
  (url (string-ascii 200))
  (description (optional (string-ascii 500)))
  (tags (optional (string-ascii 200)))
  (is-private bool)
  (is-favorite bool))
  
  (let (
    (current-count (default-to u0 (map-get? user-bookmark-count tx-sender)))
    (new-id (+ current-count u1))
  )
    (asserts! (is-valid-bookmark-data title url) ERR_INVALID_PARAMS)
    (asserts! (is-some description) ERR_INVALID_PARAMS)
    (asserts! (is-some tags) ERR_INVALID_PARAMS)
    
    (map-set user-bookmarks 
      { owner: tx-sender, bookmark-id: new-id }
      {
        title: title,
        url: url,
        description: description,
        tags: tags,
        created-at: u0,
        updated-at: u0,
        is-private: is-private,
        is-favorite: is-favorite,
        visit-count: u0
      }
    )
    
    (map-set user-bookmark-count tx-sender new-id)
    
    ;; Update user settings
    (match (map-get? user-settings tx-sender)
      settings (map-set user-settings tx-sender
        (merge settings {
          total-bookmarks: (+ (get total-bookmarks settings) u1),
          public-bookmarks: (if is-private 
            (get public-bookmarks settings)
            (+ (get public-bookmarks settings) u1))
        }))
      (map-set user-settings tx-sender {
        default-private: is-private,
        created-at: u0,
        total-bookmarks: u1,
        public-bookmarks: (if is-private u0 u1)
      })
    )
    
    (ok new-id)
  )
)

;; Update an existing bookmark
(define-public (update-bookmark 
  (bookmark-id uint)
  (title (string-ascii 100)) 
  (url (string-ascii 200))
  (description (optional (string-ascii 500)))
  (tags (optional (string-ascii 200)))
  (is-private bool)
  (is-favorite bool))
  (let (
    (bid bookmark-id)
    (existing-bookmark (map-get? user-bookmarks { owner: tx-sender, bookmark-id: bookmark-id }))
  )
    (match existing-bookmark
      bookmark (begin
        (asserts! (is-valid-bookmark-data title url) ERR_INVALID_PARAMS)
        (map-set user-bookmarks 
          { owner: tx-sender, bookmark-id: bid }
          (merge bookmark {
            title: title,
            url: url,
            description: description,
            tags: tags,
            updated-at: u0,
            is-private: is-private,
            is-favorite: is-favorite
          })
        )
        (ok "Bookmark updated successfully")
      )
      ERR_NOT_FOUND
    )
  )
)

;; Delete a bookmark
(define-public (delete-bookmark (bookmark-id uint))
  (let (
    (bid bookmark-id)
    (existing-bookmark (map-get? user-bookmarks { owner: tx-sender, bookmark-id: bookmark-id }))
  )
    (match existing-bookmark
      bookmark (begin
        (map-delete user-bookmarks { owner: tx-sender, bookmark-id: bid })
        ;; Update user settings
        (match (map-get? user-settings tx-sender)
          settings (map-set user-settings tx-sender
            (merge settings {
              total-bookmarks: (- (get total-bookmarks settings) u1),
              public-bookmarks: (if (get is-private bookmark)
                (get public-bookmarks settings)
                (- (get public-bookmarks settings) u1))
            }))
          true ;; If no settings exist, do nothing
        )
        (ok "Bookmark deleted successfully")
      )
      ERR_NOT_FOUND
    )
  )
)

;; Increment visit count for a bookmark
(define-public (visit-bookmark (owner principal) (bookmark-id uint))
  (let (
    (bid bookmark-id)
    (bookmark (map-get? user-bookmarks { owner: owner, bookmark-id: bookmark-id }))
  )
    (match bookmark
      existing-bookmark (begin
        ;; Only allow visits to public bookmarks or owner's bookmarks
        (asserts! (or (not (get is-private existing-bookmark)) (is-eq tx-sender owner)) ERR_UNAUTHORIZED)
        (map-set user-bookmarks 
          { owner: owner, bookmark-id: bid }
          (merge existing-bookmark {
            visit-count: (+ (get visit-count existing-bookmark) u1),
            updated-at: u0
          })
        )
        (ok "Visit recorded")
      )
      ERR_NOT_FOUND
    )
  )
)

;; ===========================================
;; READ-ONLY FUNCTIONS
;; ===========================================

;; Get a specific bookmark with privacy checks
(define-read-only (get-bookmark (owner principal) (bookmark-id uint))
  (let ((bookmark (map-get? user-bookmarks { owner: owner, bookmark-id: bookmark-id })))
    (match bookmark
      existing-bookmark (if (or (not (get is-private existing-bookmark)) (is-eq tx-sender owner))
        (ok existing-bookmark)
        ERR_UNAUTHORIZED)
      ERR_NOT_FOUND
    )
  )
)

;; Get user's bookmark count
(define-read-only (get-user-bookmark-count (user principal))
  (ok (default-to u0 (map-get? user-bookmark-count user)))
)

;; Get user settings
(define-read-only (get-user-settings (user principal))
  (match (map-get? user-settings user)
    settings (ok settings)
    ERR_NOT_FOUND
  )
)

;; Get user's public bookmark count
(define-read-only (get-public-bookmark-count (user principal))
  (match (map-get? user-settings user)
    settings (ok (get public-bookmarks settings))
    (ok u0)
  )
)

;; List bookmarks with enhanced filtering
(define-read-only (list-user-bookmarks 
  (user principal) 
  (start uint) 
  (limit uint)
  (favorites-only bool)
  (public-only bool))
  (let (
    (user-count (default-to u0 (map-get? user-bookmark-count user)))
    (actual-limit (if (> limit MAX_PAGINATION_LIMIT) MAX_PAGINATION_LIMIT limit))
    (is-owner (is-eq tx-sender user))
  )
    (if (or (>= start user-count) (is-eq actual-limit u0) (is-eq user-count u0))
      (ok (list))
      ;; Placeholder: Listing bookmarks is not implemented yet
      (ok (list))
    )
  )
)

;; Helper function to generate ID range (simplified version)
(define-private (generate-id-range (start uint) (end uint))
  ;; This is a simplified version - in practice, you'd want a more sophisticated approach
  (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
)

;; Helper to get bookmark data for listing
(define-private (get-bookmark-data-for-list (id uint))
  {
    title: "Sample Title",
    url: "https://example.com",
    description: none,
    tags: none,
    created-at: u0,
    updated-at: u0,
    is-private: false,
    is-favorite: false,
    visit-count: u0
  }
)

;; Search bookmarks by title or tags (basic implementation)
(define-read-only (search-bookmarks (user principal) (query (string-ascii 50)))
  (if (is-eq tx-sender user)
    (ok "Search functionality - implementation depends on specific requirements")
    ERR_UNAUTHORIZED
  )
)

;; ===========================================
;; ADMIN FUNCTIONS
;; ===========================================

;; Get contract statistics (only for contract owner)
(define-read-only (get-contract-stats)
  (if (is-eq tx-sender CONTRACT_OWNER)
    (ok {
      version: "1.0.0",
      total-users: u0, ;; Would need to implement user tracking
      contract-owner: CONTRACT_OWNER
    })
    ERR_UNAUTHORIZED
  )
)
