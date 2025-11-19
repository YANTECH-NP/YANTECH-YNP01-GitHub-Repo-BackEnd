'use client'

import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import { IoLogOutOutline, IoShield } from "react-icons/io5";
import { MdDashboard } from "react-icons/md";

export default function Header() {
  const { logout, user } = useAuth()
  const router = useRouter()

  const handleLogout = () => {
    logout()
    router.push('/login')
  }

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary-100 rounded-lg">
              <MdDashboard className="w-6 h-6 text-primary-600" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">
                Admin Dashboard
              </h1>
              <p className="text-xs text-gray-500">YANTECH Notification System</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <IoShield className="w-4 h-4" />
              <span>Welcome, {user?.username}</span>
            </div>

            <button onClick={handleLogout} className="flex gap-2 btn-danger p-1 rounded">
              <IoLogOutOutline className="w-4 h-4 mt-1" />
              Logout
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}