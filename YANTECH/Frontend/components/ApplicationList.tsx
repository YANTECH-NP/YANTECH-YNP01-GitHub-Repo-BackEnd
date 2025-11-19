'use client'

import { useRouter } from 'next/navigation'
import { useState, useEffect } from "react";
import {
  IoEyeSharp,
  IoTrashSharp,
  IoMailSharp,
  IoGlobeSharp,
} from "react-icons/io5";
import { FaEdit, FaCircle } from "react-icons/fa";
import type { Application, ApplicationListProps } from "@/types";
import { deleteApplication, getApplicationApiKeys } from "@/services/api";

export default function ApplicationList({
  applications,
  onUpdate,
}: ApplicationListProps) {
  const router = useRouter();
  const [appStatuses, setAppStatuses] = useState<Record<string, boolean>>({});

  // Fetch API keys for all applications to determine active status
  useEffect(() => {
    const fetchApiKeysForApps = async () => {
      const statuses: Record<string, boolean> = {};

      await Promise.all(
        applications.map(async (app) => {
          try {
            const apiKeys = await getApplicationApiKeys(app.Application);
            // Application is active if it has at least one non-revoked API key
            const hasActiveKey = apiKeys.some((key) => key.is_active);
            statuses[app.Application] = hasActiveKey;
          } catch (error) {
            console.error(
              `Failed to fetch API keys for ${app.Application}:`,
              error
            );
            statuses[app.Application] = false;
          }
        })
      );

      setAppStatuses(statuses);
    };

    if (applications.length > 0) {
      fetchApiKeysForApps();
    }
  }, [applications]);

  const handleViewDetails = (app: Application) => {
    router.push(`/application/${app.Application}`);
  };

  const handleEdit = (app: Application) => {
    router.push(`/application/${app.Application}/edit`);
  };

  const handleDelete = async (app: Application) => {
    if (window.confirm(`Are you sure you want to delete ${app.App_name}?`)) {
      try {
        await deleteApplication(app.Application);
        onUpdate(); // Refresh the applications list
      } catch (error) {
        console.error("Failed to delete application:", error);
        alert("Failed to delete application. Please try again.");
      }
    }
  };

  const getStatusBadge = (appId: string) => {
    const isActive = appStatuses[appId];

    if (isActive === undefined) {
      // Still loading
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-gray-100 text-gray-500 text-xs font-medium rounded-full">
          <FaCircle className="w-2 h-2 animate-pulse" />
          Loading...
        </span>
      );
    }

    if (isActive) {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full">
          <FaCircle className="w-2 h-2" />
          Active
        </span>
      );
    }

    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">
        <FaCircle className="w-2 h-2" />
        Inactive
      </span>
    );
  };

  if (applications.length === 0) {
    return (
      <div className="card text-center py-12">
        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <IoMailSharp className="w-8 h-8 text-gray-400" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          No applications yet
        </h3>
        <p className="text-gray-500">
          Get started by registering your first application.
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {applications.map((app) => (
        <div
          key={app.Application}
          className="card hover:shadow-md transition-shadow duration-200 p-3 group"
        >
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <h3 className="text-lg font-semibold text-gray-900 group-hover:text-primary-600 transition-colors">
                  {app.App_name}
                </h3>
                {getStatusBadge(app.Application)}
              </div>
              <span className="inline-block px-2 py-1 bg-gray-100 text-gray-600 text-xs font-medium rounded">
                {app.Application}
              </span>
            </div>
          </div>

          <div className="space-y-3 mb-6">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <IoMailSharp className="w-4 h-4" />
              <span className="truncate">{app.Email}</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <IoGlobeSharp className="w-4 h-4" />
              <span className="truncate">{app.Domain}</span>
            </div>
          </div>

          <div className="flex gap-2">
            <button
              onClick={() => handleViewDetails(app)}
              className="flex-1 bg-primary-50 hover:bg-primary-100 text-primary-600 font-medium py-2 px-3 rounded-lg transition-colors duration-200 flex items-center justify-center gap-2"
              title="View Details"
            >
              <IoEyeSharp className="w-4 h-4" />
              View
            </button>
            <button
              onClick={() => handleEdit(app)}
              className="bg-gray-100 hover:bg-gray-200 text-gray-600 font-medium py-2 px-3 rounded-lg transition-colors duration-200 flex items-center justify-center"
              title="Edit Application"
            >
              <FaEdit className="w-4 h-4" />
            </button>
            <button
              onClick={() => handleDelete(app)}
              className="bg-danger-50 hover:bg-danger-100 text-danger-600 font-medium py-2 px-3 rounded-lg transition-colors duration-200 flex items-center justify-center"
              title="Delete Application"
            >
              <IoTrashSharp className="w-4 h-4" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
