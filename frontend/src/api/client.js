import axios from 'axios';

const API_BASE_URL = 'http://localhost:5001/api';

export const updateBooking = async (bookingId, updateData) => {
  // Calls proc_update_booking via backend
  const response = await apiClient.put(`/bookings/${bookingId}`, updateData);
  return response.data;
};

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// --- Authentication ---
export const loginUser = async (email) => {
  const response = await apiClient.post('/login', { email });
  return response.data;
};

export const signupUser = async (userData) => {
  // Matches proc_create_customer parameters
  const response = await apiClient.post('/signup', userData);
  return response.data;
};

// --- Static Data ---
export const fetchStaticData = async () => {
  const response = await apiClient.get('/static_data');
  return response.data;
};

// --- Search & Booking ---
export const searchCars = async (params) => {
  // Matches fn_is_car_available logic via backend
  const response = await apiClient.get('/cars/search', {
    params: {
        branch_id: params.branch_id, 
        start_date: params.start_date, 
        end_date: params.end_date 
    }
  });
  return response.data;
};

export const createBooking = async (bookingData) => {
  // Calls proc_create_booking
  const response = await apiClient.post('/bookings', bookingData);
  return response.data;
};

export const fetchCustomerBookings = async (custId) => {
  const response = await apiClient.get(`/bookings/customer/${custId}`);
  return response.data;
};

export const cancelBooking = async (bookingId) => {
  // Calls proc_cancel_booking
  const response = await apiClient.post(`/bookings/${bookingId}/cancel`);
  return response.data;
};

// --- Payment ---
export const makePayment = async (data) => {
  // Calls proc_create_payment
  const response = await apiClient.post('/payments', data);
  return response.data;
};

// --- Admin / Employee ---
export const loginEmployee = async (email) => {
  const response = await apiClient.post('/admin/login', { email });
  return response.data;
};

export const fetchAllCars = async () => {
  const response = await apiClient.get('/admin/cars');
  return response.data;
};

export const logMaintenance = async (data) => {
  // Calls proc_add_maintenance_log
  const response = await apiClient.post('/admin/maintenance', data);
  return response.data;
};

export const fetchBookingsWithML = async () => {
  const response = await apiClient.get('/admin/bookings/ml');
  return response.data;
};