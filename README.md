Here’s a formatted `README.md` for your smart contract, ready to submit on GitHub:

---

# BookmarkHub Smart Contract

A decentralized bookmark management system built on the Stacks blockchain.

## Features

- Add, update, and delete bookmarks with metadata (title, URL, description, tags, privacy, favorite, visit count)
- User-specific bookmark storage and counters
- Privacy controls (public/private bookmarks)
- Bookmark visit tracking
- User settings and preferences
- Bookmark collections (categories)
- Pagination and filtering for bookmark lists
- Error handling and input validation

## Data Structures

- `user-bookmarks`: Stores bookmarks for each user with metadata
- `user-bookmark-count`: Tracks the number of bookmarks per user
- `user-settings`: Stores user preferences and statistics
- `bookmark-collections`: Organizes bookmarks into collections

## Key Functions

- `create-bookmark`: Add a new bookmark with metadata
- `update-bookmark`: Update an existing bookmark
- `delete-bookmark`: Remove a bookmark
- `visit-bookmark`: Increment visit count for a bookmark
- `get-bookmark`: Retrieve a bookmark with privacy checks
- `list-user-bookmarks`: List bookmarks with pagination and filtering
- `get-user-settings`: Retrieve user settings and stats
- `get-contract-stats`: View contract statistics (admin only)

## Error Codes

- `ERR_UNAUTHORIZED`: Unauthorized action
- `ERR_NOT_FOUND`: Bookmark or user not found
- `ERR_INVALID_PARAMS`: Invalid input parameters
- `ERR_LIMIT_EXCEEDED`: Pagination or input limit exceeded

## Usage

Deploy the contract to the Stacks blockchain using [Clarinet](https://docs.stacks.co/write-smart-contracts/clarinet/overview/) or your preferred tool. Interact with the contract using Clarity calls or through a frontend.

