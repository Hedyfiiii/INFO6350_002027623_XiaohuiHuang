# HyperGarageSale

HyperGarageSale is a full-stack mobile and web application that allows users to buy and sell items easily. The app leverages Firebase for authentication, real-time database, and cloud storage, while integrating Google's ML Kit for intelligent image classification.

## Supported Platforms

- Android (API 21+)

## Features

### Authentication
- **Email/Password Sign Up & Sign In** - Secure user registration and login
- **Google Sign-In** - Quick authentication with Google accounts
- **Firebase Authentication** - Industry-standard security
- **Auto Sign-Out** - Session management with logout functionality

### Post Management
- **Create Posts** - List items for sale with title, price, and description
- **Image Upload** - Add up to 4 images per post
- **Multiple Image Sources**:
  - Take photos with camera
  - Choose from gallery
  - Select from app assets (sample images)
- **Edit & Delete** - Manage your own posts
- **Real-time Updates** - Posts appear instantly across all devices

### AI-Powered Features
- **ML Kit Image Classification** - Automatic category detection
- **Smart Labeling** - AI analyzes images and suggests relevant categories
- **Category Management** - Add, remove, or edit detected categories
- **Visual Feedback** - See classification confidence in real-time

### Browse & Search
- **Browse All Posts** - View all marketplace listings
- **Real-time Search** - Search posts by title with instant results
- **Category Filters** - Browse by AI-detected categories
- **Post Details** - View full item information with image carousel
- **Image Viewer** - Full-screen image viewing with pinch-to-zoom

### User Interface
- **Responsive Design** - Works on mobile, tablet, and desktop
- **Material Design** - Clean, modern UI following Material guidelines
- **Image Carousel** - Swipeable image galleries with indicators
- **SnackBar Notifications** - Real-time feedback for actions
- **Empty States** - Helpful messages when no content is available

### Notifications
- **New Post Alerts** - Top banner notification when new items are posted
- **Action Notifications** - Success/error messages for all operations

### Content Management
- **Delete Posts** - Remove your own listings
- **Confirmation Dialogs** - Prevent accidental deletions
- **Image Cleanup** - Automatically removes images from storage
- **Owner-Only Actions** - Security controls ensure users can only modify their own content

## Prerequisites

Before you begin, ensure you have:
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account
- Google Cloud account (for ML Kit)

## How to Use

### Getting Started

#### 1. Create an Account
- Open the app
- Tap **"Sign Up"**
- Enter your email and password OR sign in with Google
- You're ready to start!

#### 2. Browse Items
- View all items on the home screen
- Scroll through available listings
- Tap any item to see full details
- Swipe through item images
- Tap images for full-screen view with zoom

#### 3. Search for Items
- Tap the 🔍 **Search** icon in the app bar
- Type keywords to find items
- Results appear instantly as you type
- Tap any result to view details

### Creating a Post

#### 1. Add a New Post
- Tap the **+** button (bottom-right floating button)
- OR tap **menu** → "Post New Item"
- OR tap the **add icon** in the app bar

#### 2. Add Photos
- Tap **"Add Photo"**
- Choose from:
  - **Take Photo** - Capture with camera
  - **Choose from Gallery** - Select existing photos
  - **Use Assets Image** - Pick sample images
- Add up to 4 photos per post
- AI will automatically analyze and categorize your images

#### 3. Review AI Categories
- **Purple chips** show detected categories
- Tap the **✕** on any category to remove it
- Tap **"Clear All"** to remove all categories
- Categories help buyers find your items

#### 4. Fill in Details
- **Title**: Descriptive name for your item
- **Price**: Item price (numbers only)
- **Description**: Detailed information about the item

#### 5. Post Your Item
- Tap **"Post Classified"** button
- Wait for upload to complete
- Your item appears instantly in the feed!

### Managing Your Posts

#### View Your Posts
- Browse the main feed
- Your posts show a 🗑️ **delete icon** (only you can see this)

#### Delete a Post
- Find your post in the feed
- Tap the red **trash icon**
- Confirm deletion
- Images and post data are permanently removed

### Viewing Post Details

#### Open a Post
- Tap any post card from the feed or search results

#### Image Carousel
- Swipe left/right to view all images
- Dots below images show your position
- Tap any image for full-screen view
- Pinch to zoom in full-screen mode

#### Post Information
- View title, price, and description
- See AI-detected categories
- Check posting date and time

#### Contact Seller (Coming Soon)
- Tap **"Contact Seller"** button
- Future feature for messaging

### Additional Features

#### Logout
- Tap the **menu** icon (three dots)
- Select **"Logout"**
- Returns to sign-in screen

#### Real-time Updates
- New posts appear automatically with a notification banner
- All changes sync instantly across devices

## Key Workflows

### Quick Post Creation
```
Home → + Button → Add Photos → AI Analysis → Fill Details → Post
```

### Finding Items
```
Home → Search Icon → Type Keywords → View Results → Tap Item
```

### Delete Your Post
```
Home → Find Your Post → Tap Delete Icon → Confirm → Done
```