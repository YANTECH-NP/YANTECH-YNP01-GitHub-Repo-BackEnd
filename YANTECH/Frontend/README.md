# Admin Frontend - Next.js

Modern React frontend built with Next.js 14, TypeScript, and Tailwind CSS for the Notification System Admin service.

## ✨ Features

- **Modern Stack**: Next.js 14 with App Router, TypeScript, ESLint
- **Elegant UI**: Tailwind CSS with custom design system
- **Authentication**: Secure admin login system
- **Application Management**: Create, view, edit, and delete applications
- **AWS Integration**: Automatic SES and SNS resource configuration
- **Notification Tracking**: Real-time notification history and status
- **Responsive Design**: Mobile-first responsive layout
- **Performance**: Optimized with Next.js features

## 🚀 Quick Start

1. **Install dependencies:**
```bash
npm install
```

2. **Set up environment:**
```bash
cp .env.local.example .env.local
```

3. **Update API URL in `.env.local`:**
```env
NEXT_PUBLIC_API_URL=http://localhost:8001
```

4. **Start development server:**
```bash
npm run dev
```

5. **Open browser:**
Navigate to [http://localhost:3000](http://localhost:3000)

## 🔐 Authentication

**Default Credentials:**
- Username: `admin`
- Password: `admin123`

## 🏗️ Project Structure

```
src/
├── app/                    # Next.js App Router
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home page
│   ├── login/             # Login page
│   ├── dashboard/         # Dashboard page
│   └── application/[id]/  # Application detail page
├── components/            # Reusable components
│   ├── Header.tsx
│   ├── ApplicationForm.tsx
│   └── ApplicationList.tsx
├── contexts/              # React contexts
│   └── AuthContext.tsx
├── services/              # API services
│   └── api.ts
└── types/                 # TypeScript types
    └── index.ts
```

## 🎨 Design System

The application uses a custom design system built with Tailwind CSS:

- **Colors**: Primary blue, success green, warning orange, danger red
- **Typography**: Inter font family with consistent sizing
- **Components**: Reusable button, input, and card components
- **Animations**: Smooth transitions and micro-interactions

## 📱 Responsive Design

- **Mobile First**: Optimized for mobile devices
- **Breakpoints**: sm (640px), md (768px), lg (1024px), xl (1280px)
- **Grid System**: CSS Grid and Flexbox for layouts
- **Touch Friendly**: Large touch targets and gestures

## 🔧 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## 🚀 Deployment

### Vercel (Recommended)

1. Push to GitHub repository
2. Connect to Vercel
3. Set environment variables
4. Deploy automatically

### Docker

```bash
# Build image
docker build -t admin-frontend .

# Run container
docker run -p 3000:3000 admin-frontend
```

### Static Export

```bash
npm run build
npm run export
```

## 🔗 API Integration

The frontend connects to the Admin service API:

- **Base URL**: `http://localhost:8001`
- **Endpoints**:
  - `GET /apps` - List applications
  - `POST /app` - Create application
  - `PUT /app/:id` - Update application
  - `DELETE /app/:id` - Delete application

## 🎯 Features Overview

### Dashboard
- Application overview cards
- Quick actions and statistics
- Responsive grid layout

### Application Management
- Create new applications with form validation
- View detailed application information
- Edit and delete existing applications

### Notification Tracking
- Real-time notification history
- Status indicators (sent, pending, failed)
- Detailed notification information

### AWS Resource Management
- Automatic SES domain verification
- SNS topic creation and configuration
- Resource ARN display and management

## 🔒 Security

- Client-side authentication with JWT tokens
- Protected routes with authentication guards
- Secure API communication
- Input validation and sanitization

## 🌟 Performance

- Next.js App Router for optimal performance
- Static generation where possible
- Image optimization
- Code splitting and lazy loading
- Optimized bundle size

## 📄 License

This project is licensed under the MIT License.
trigger