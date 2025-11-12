![omnibin header](/assets/readme/readme-header.png)

# omnibin

**Copy. Paste. Anywhere.**

Seamless cross-platform clipboard synchronization. Move text, images, and files between devices with ease. One click copy and paste across all your devices.

## How to get omnibin

### Web

[omnib.in](https://omnib.in/)

### iOS

[App Store](https://apps.apple.com/us/app/omnibin/id6752793228)

## Features & Capabilities

- **Cross-platform support** - Share one bin on all devices (Web, iOS)
- **Effortless sharing** - One click copy and paste
- **Fast, secure sync** - Backed by modern auth and storage
- **Text and file sharing** - Support for text, images, and files
- **Real-time synchronization** - Instant updates across devices
- **Image previews** - Automatic previews for files and url's
- **Share extensions** - Native ios sharing integration
- **Secure authentication** - Powered by Auth0
- **Cloud storage** - Reliable AWS S3 backend

## Architecture & Tech Stack

### Web Application
- **Frontend**: Next.js 15, React 19, TypeScript
- **Styling**: Shadcn, Tailwind CSS

### Mobile Applications
- **iOS**: Native Swift app with share extension
- **Features**: Native clipboard integration, share extension for easy content sharing

### Backend
- **Authentication**: Auth0 integration
- **Database**: PostgreSQL with Prisma ORM
- **Storage**: AWS S3 for file storage
- **Deployment**: Vercel

## Security & Privacy

- **Authentication**: Secure Auth0 integration with industry-standard protocols
- **Data encryption**: All data encrypted in transit and at rest
- **File storage**: Secure AWS S3 storage with proper access controls
- **Privacy**: User data is handled according to the [privacy policy](https://omnib.in/privacy-policy)
- **Session management**: Secure session handling with automatic expiration

## License & Legal

- **License**: [LICENSE](LICENSE)
- **Privacy Policy**: [Link](https://omnib.in/privacy-policy)
- **Support**: [Link](https://omnib.in/support)