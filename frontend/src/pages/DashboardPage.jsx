import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchCustomerBookings, cancelBooking, updateBooking, fetchStaticData } from '../api/client';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/card';
import { LogOut, Car, Calendar, MapPin, X, Save, Edit2 } from 'lucide-react';

const DashboardPage = () => {
    const navigate = useNavigate();
    const user = JSON.parse(localStorage.getItem('user'));
    
    // Data State
    const [bookings, setBookings] = useState([]);
    const [staticData, setStaticData] = useState({ insurance: [] });
    const [loading, setLoading] = useState(true);

    // Editing State
    const [editingId, setEditingId] = useState(null);
    const [editForm, setEditForm] = useState({});
    const [updateError, setUpdateError] = useState('');

    useEffect(() => {
        if (!user) {
            navigate('/');
            return;
        }
        loadData();
    }, []);

    const loadData = async () => {
        try {
            const [bookingsData, staticDataRes] = await Promise.all([
                fetchCustomerBookings(user.cust_id),
                fetchStaticData()
            ]);
            setBookings(bookingsData);
            setStaticData(staticDataRes);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    // Helper: Format date for SQL (YYYY-MM-DD HH:MM:SS)
    const toSqlDate = (dateStr) => dateStr.replace('T', ' ') + ':00';
    
    // Helper: Format date for Input field (YYYY-MM-DDTHH:MM)
    const toInputDate = (dateStr) => {
        if(!dateStr) return '';
        const d = new Date(dateStr);
        
        const pad = (n) => n.toString().padStart(2, '0');
        return `${d.getUTCFullYear()}-${pad(d.getUTCMonth()+1)}-${pad(d.getUTCDate())}T${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}`;
    };

    const handleCancel = async (bookingId) => {
        if(!window.confirm("Are you sure you want to cancel this booking?")) return;
        try {
            await cancelBooking(bookingId);
            loadData();
        } catch (err) {
            alert("Failed to cancel booking.");
        }
    };

    const startEditing = (booking) => {
        setEditingId(booking.booking_id);
        setUpdateError('');
        setEditForm({
            start_datetime: toInputDate(booking.start_datetime),
            end_datetime: toInputDate(booking.end_datetime),
           
            insurance_policy_id: booking.insurance_policy_id ? String(booking.insurance_policy_id) : '1',
            promo_code: booking.promo_code || ''
        });
    };

    const saveEdit = async () => {
        setUpdateError('');
        try {
            await updateBooking(editingId, {
                start_datetime: toSqlDate(editForm.start_datetime),
                end_datetime: toSqlDate(editForm.end_datetime),
                insurance_policy_id: editForm.insurance_policy_id,
                promo_code: editForm.promo_code || null
            });
            setEditingId(null);
            loadData(); // Refresh to see new price/status
        } catch (err) {
            setUpdateError(err.response?.data?.error || 'Update failed');
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('user');
        navigate('/');
    };

    const getStatusColor = (status) => {
        switch(status) {
            case 'Confirmed': return 'bg-green-100 text-green-700 border-green-200';
            case 'Booked': return 'bg-blue-100 text-blue-700 border-blue-200';
            case 'Cancelled': return 'bg-red-100 text-red-700 border-red-200';
            case 'Completed': return 'bg-gray-100 text-gray-700 border-gray-200';
            default: return 'bg-gray-50 border-gray-200';
        }
    };

    return (
        <div className="min-h-screen bg-slate-50 p-4 sm:p-8">
            <div className="max-w-5xl mx-auto space-y-6">
                {/* Header */}
                <div className="flex flex-col md:flex-row justify-between items-center bg-white p-6 rounded-lg shadow-sm border">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-800">My Dashboard</h1>
                        <p className="text-slate-500">Manage your reservations</p>
                    </div>
                    <div className="flex gap-3 mt-4 md:mt-0">
                        <Button onClick={() => navigate('/book')} className="shadow-md">
                            <Car className='w-4 h-4 mr-2'/> New Booking
                        </Button>
                        <Button onClick={handleLogout} variant="outline" className="text-red-600 hover:bg-red-50">
                            <LogOut className='w-4 h-4 mr-2'/> Logout
                        </Button>
                    </div>
                </div>

                {/* Bookings List */}
                <div className="space-y-4">
                    <h2 className="text-xl font-semibold text-slate-800">Your Bookings</h2>
                    
                    {loading ? (
                        <p>Loading bookings...</p>
                    ) : bookings.length === 0 ? (
                        <Card className="p-8 text-center text-gray-500">
                            <p>You haven't made any bookings yet.</p>
                            <Button variant="link" onClick={() => navigate('/book')}>Find a car now</Button>
                        </Card>
                    ) : (
                        <div className="grid gap-4">
                            {bookings.map((booking) => (
                                <Card key={booking.booking_id} className={`overflow-hidden border-l-4 shadow-sm transition-all ${editingId === booking.booking_id ? 'border-l-blue-500 ring-2 ring-blue-100' : 'border-l-primary'}`}>
                                    <CardContent className="p-6">
                                        
                                        {/* EDIT MODE */}
                                        {editingId === booking.booking_id ? (
                                            <div className="space-y-4">
                                                <div className="flex justify-between items-center mb-2">
                                                    <h3 className="font-bold text-lg">Modify Reservation #{booking.booking_id}</h3>
                                                    <Button variant="ghost" size="sm" onClick={() => setEditingId(null)}><X className="w-4 h-4"/></Button>
                                                </div>
                                                
                                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                    <div className="space-y-1">
                                                        <label className="text-xs font-semibold uppercase text-gray-500">Start Date</label>
                                                        <Input 
                                                            type="datetime-local" 
                                                            value={editForm.start_datetime}
                                                            onChange={(e) => setEditForm({...editForm, start_datetime: e.target.value})}
                                                        />
                                                    </div>
                                                    <div className="space-y-1">
                                                        <label className="text-xs font-semibold uppercase text-gray-500">End Date</label>
                                                        <Input 
                                                            type="datetime-local" 
                                                            value={editForm.end_datetime}
                                                            onChange={(e) => setEditForm({...editForm, end_datetime: e.target.value})}
                                                        />
                                                    </div>
                                                    <div className="space-y-1">
                                                        <label className="text-xs font-semibold uppercase text-gray-500">Insurance (Mandatory)</label>
                                                        {/* UPDATED: Removed No Insurance option */}
                                                        <Select value={editForm.insurance_policy_id} onValueChange={(v) => setEditForm({...editForm, insurance_policy_id: v})}>
                                                            <SelectTrigger><SelectValue placeholder="Select Insurance" /></SelectTrigger>
                                                            <SelectContent>
                                                                {staticData.insurance.map(i => (
                                                                    <SelectItem key={i.policy_id} value={String(i.policy_id)}>{i.package_name} (+${i.daily_cost})</SelectItem>
                                                                ))}
                                                            </SelectContent>
                                                        </Select>
                                                    </div>
                                                    <div className="space-y-1">
                                                        <label className="text-xs font-semibold uppercase text-gray-500">Promo Code</label>
                                                        <Input 
                                                            placeholder="Promo Code"
                                                            value={editForm.promo_code}
                                                            onChange={(e) => setEditForm({...editForm, promo_code: e.target.value})}
                                                        />
                                                    </div>
                                                </div>

                                                {updateError && <p className="text-sm text-red-600 bg-red-50 p-2 rounded">{updateError}</p>}

                                                <div className="flex justify-end gap-2 pt-2">
                                                    <Button variant="outline" onClick={() => setEditingId(null)}>Cancel</Button>
                                                    <Button onClick={saveEdit}><Save className="w-4 h-4 mr-2"/> Save Changes</Button>
                                                </div>
                                            </div>
                                        ) : (
                                        /* VIEW MODE */
                                            <div className="flex flex-col md:flex-row justify-between">
                                                <div className="space-y-3">
                                                    <div className="flex items-center gap-3">
                                                        <h3 className="text-xl font-bold">{booking.car_make} {booking.car_model}</h3>
                                                        <span className={`text-xs px-2 py-1 rounded border font-medium ${getStatusColor(booking.status)}`}>
                                                            {booking.status}
                                                        </span>
                                                    </div>
                                                    <div className="text-sm text-gray-500 space-y-1">
                                                        <div className="flex items-center gap-2">
                                                            <Calendar className="w-4 h-4 text-slate-400" /> 
                                                            
                                                            {new Date(booking.start_datetime).toLocaleString(undefined, { timeZone: 'UTC' })} 
                                                            <span className="text-slate-300">➜</span> 
                                                            {new Date(booking.end_datetime).toLocaleString(undefined, { timeZone: 'UTC' })}
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <MapPin className="w-4 h-4 text-slate-400" /> 
                                                            Pickup Branch ID: {booking.pickup_branch_id}
                                                        </div>
                                                    </div>
                                                </div>

                                                <div className="mt-4 md:mt-0 flex flex-col items-end justify-between">
                                                    <div className="text-right">
                                                        <p className="text-sm text-gray-400">Total</p>
                                                        <p className="text-2xl font-bold text-slate-800">${booking.total_amount}</p>
                                                    </div>
                                                    
                                                    {(booking.status === 'Confirmed' || booking.status === 'Booked') && (
                                                        <div className="flex gap-2 mt-3">
                                                            <Button variant="outline" size="sm" onClick={() => startEditing(booking)}>
                                                                <Edit2 className="w-3 h-3 mr-2"/> Modify
                                                            </Button>
                                                            <Button 
                                                                variant="destructive" 
                                                                size="sm" 
                                                                onClick={() => handleCancel(booking.booking_id)}
                                                            >
                                                                Cancel
                                                            </Button>
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        )}
                                    </CardContent>
                                </Card>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default DashboardPage;