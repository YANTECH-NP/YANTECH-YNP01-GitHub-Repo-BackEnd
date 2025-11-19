import axios from "axios";
import type {
  ApiKey,
  ApiCreationFormData,
  Application,
  ApplicationFormData,
  Notification,
  NotificationRequest,
  NotificationResponse,
  APIKeyInfo,
} from "@/types";

// Use the Next.js API proxy to avoid CORS issues
const APPS_BASE_URL = "/api/proxy";
const REQUESTOR_BASE_URL = "/api/requestor";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://54.196.198.21:80";

// Test backend connection
export const testConnection = async (): Promise<boolean> => {
  try {
    const response = await fetch(`${API_BASE_URL}/`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    console.log("✅ Backend connection successful:", data);
    return true;
  } catch (error) {
    console.error("❌ Backend connection failed:", error);
    return false;
  }
};

const api = axios.create({
  baseURL: APPS_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

const apiRequestor = axios.create({
  baseURL: REQUESTOR_BASE_URL, // rewrites to port 80
  headers: {
    "Content-Type": "application/json",
  },
});

export const getApplications = async (): Promise<Application[]> => {
  console.log("[getApplications] Sending GET request to /applications");

  try {
    const response = await api.get("/applications");

    console.log(
      "[getApplications] Response received:",
      response.status,
      response.data
    );
    return response.data;
  } catch (error: any) {
    console.error("[getApplications] Error occurred:", {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
    });

    throw new Error(
      error.response?.data?.detail || "Failed to fetch applications"
    );
  }
};

export const createApplication = async (
  applicationData: ApplicationFormData
): Promise<Application> => {
  console.debug("[createApplication] Input data:", applicationData);

  try {
    // Step 1: Create the application
    const response = await api.post("/applications", applicationData);
    console.debug("[createApplication] Response status:", response.status);
    console.debug("[createApplication] Response data:", response.data);

    const createdApp = response.data;

    // Step 2: Generate API key for the created application
    try {
      const apiKeyResponse = await api.post(`/applications/${createdApp.id}/api-key`, {
        // Optional: include any metadata for the API key
        name: `API Key for ${createdApp.name || "Application"}`,
        expires_at: null, // null for no expiration, or a date string
      });

      console.debug(
        "[createApplication] API Key generated:",
        apiKeyResponse.data
      );

      // Step 3: Return the application with the API key attached
      return {
        ...createdApp,
        apiKey: apiKeyResponse.data.api_key,
        apiKeyId: apiKeyResponse.data.id,
      };
    } catch (apiKeyError: any) {
      console.error(
        "[createApplication] API Key generation failed:",
        apiKeyError
      );
      // Application was created but API key failed
      // You could either:
      // 1. Return the app without the key (partial success)
      // 2. Delete the app and throw an error (atomic operation)

      // Option 2: Rollback - delete the created app
      try {
        await api.delete(`/applications/${createdApp.id}`);
        console.debug("[createApplication] Rolled back application creation");
      } catch (deleteError) {
        console.error("[createApplication] Rollback failed:", deleteError);
      }

      throw new Error(
        apiKeyError.response?.data?.detail || "Failed to generate API key"
      );
    }
  } catch (error: any) {
    console.error("[createApplication] Error:", error);
    console.error(
      "[createApplication] Error details:",
      error.response?.data || error.message
    );
    throw new Error(
      error.response?.data?.detail || "Failed to create application -api"
    );
  }
};

export const createApiKey = async (
  apiCreationData: ApiCreationFormData
): Promise<ApiKey> => {
  // Step 2: Generate API key for the created application
  try {
    const apiKeyResponse = await api.post(
      `/applications/${apiCreationData.Api_id}/api-key`,
      apiCreationData
    );

    console.debug("[createApiKey] API Key generated:", apiKeyResponse.data);

    const apikey = apiKeyResponse.data;

    return apikey;
  } catch (apiKeyError: any) {
    console.error(
      "[createApplication] API Key generation failed:",
      apiKeyError
    );
    return apiKeyError;
  }
};

export const requestNotification = async (
  notificationData: NotificationRequest
): Promise<NotificationResponse> => {
  console.log(
    "[requestNotification] Sending notification request:",
    notificationData
  );

  try {
    const response = await apiRequestor.post("/request", notificationData);

    console.log(
      "[requestNotification] Response received:",
      response.status,
      response.data
    );

    return response.data;
  } catch (error: any) {
    console.error("[requestNotification] Error occurred:", {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
    });

    throw new Error(
      error.response?.data?.detail || "Failed to send notification request"
    );
  }
};

export const updateApplication = async (
  id: string,
  applicationData: ApplicationFormData
): Promise<Application> => {
  try {
    const response = await api.put(`/applications/${id}`, applicationData);
    return response.data;
  } catch (error: any) {
    console.error(
      "[updateApplication] Error details:",
      error.response?.data || error.message
    );
    throw new Error("Failed to update application");
  }
};

export const deleteApplication = async (id: string): Promise<void> => {
  try {
    await api.delete(`/applications/${id}`);
  } catch (error: any) {
    throw new Error("Failed to delete application");
  }
};

export const getNotifications = async (
  applicationId: string
): Promise<Notification[]> => {
  try {
    const response = await api.get(`/applications/${applicationId}/notifications`);
    return response.data;
  } catch (error: any) {
    throw new Error("Failed to fetch notifications");
  }
};

export const getApplicationApiKeys = async (
  applicationId: string
): Promise<APIKeyInfo[]> => {
  try {
    const response = await api.get(`/applications/${applicationId}/api-keys`);
    return response.data;
  } catch (error: any) {
    console.error("[getApplicationApiKeys] Error:", error);
    // Return empty array if API keys endpoint fails
    return [];
  }
};
