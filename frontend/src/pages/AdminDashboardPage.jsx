import React, { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchAllCars, logMaintenance, fetchBookingsWithML } from '../api/client';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '../components/ui/card';
import { Wrench, TrendingUp, LogOut, Car, Activity } from 'lucide-react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, 
  PieChart as RePieChart, Pie, Cell, AreaChart, Area
} from 'recharts';

const AdminDashboardPage = () => {
  const navigate = useNavigate();
  // Safe parsing of employee data
  const employeeStr = localStorage.getItem('employee');
  const employee = employeeStr ? JSON.parse(employeeStr) : null;
  
  const [activeTab, setActiveTab] = useState('overview');
  const [cars, setCars] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);

  // Maintenance Form State
  const [selectedCar, setSelectedCar] = useState(null);
  const [maintForm, setMaintForm] = useState({ description: '', cost: '', date_in: '' });

  useEffect(() => {
    if (!employee) {
        navigate('/admin');
        return;
    }
    loadData();
  }, [employee, navigate]);

  const loadData = async () => {
    setLoading(true);
    try {
        const [carsData, bookingsData] = await Promise.all([
            fetchAllCars(),
            fetchBookingsWithML()
        ]);
        setCars(carsData);
        setBookings(bookingsData);
    } catch (err) { console.error(err); } 
    finally { setLoading(false); }
  };

  const handleMaintenanceSubmit = async (e) => {
    e.preventDefault();
    if(!selectedCar) return;
    try {
        await logMaintenance({
            car_id: selectedCar.car_id,
            emp_id: employee.emp_id,
            date_in: maintForm.date_in.replace('T', ' ') + ':00',
            date_out: null,
            description: maintForm.description,
            cost: maintForm.cost
        });
        alert('Maintenance logged successfully. Car status updated.');
        setSelectedCar(null);
        loadData();
    } catch (err) {
        alert('Failed to log maintenance: ' + (err.response?.data?.error || err.message));
    }
  };

  const getStatusBadge = (status) => {
    const colors = {
        'Available': 'bg-green-100 text-green-800',
        'Booked': 'bg-blue-100 text-blue-800',
        'Maintenance': 'bg-red-100 text-red-800',
        'Retired': 'bg-gray-100 text-gray-800'
    };
    return <span className={`px-2 py-1 rounded-full text-xs font-bold ${colors[status] || 'bg-gray-100'}`}>{status}</span>;
  };

  // --- CHART DATA PROCESSING ---

  // 1. Fleet Status Distribution (Donut Chart)
  const fleetStatusData = useMemo(() => {
    const counts = cars.reduce((acc, car) => {
        acc[car.status] = (acc[car.status] || 0) + 1;
        return acc;
    }, {});
    return Object.keys(counts).map(key => ({ name: key, value: counts[key] }));
  }, [cars]);

  // 2. Branch Distribution (Bar Chart)
  const branchData = useMemo(() => {
    const counts = cars.reduce((acc, car) => {
        acc[car.branch_name] = (acc[car.branch_name] || 0) + 1;
        return acc;
    }, {});
    return Object.keys(counts).map(key => ({ name: key, cars: counts[key] }));
  }, [cars]);

  // 3. Revenue & Bookings over time (Area Chart)
  const revenueData = useMemo(() => {
    // Reverse to show oldest to newest ( API returns DESC)
    return [...bookings].reverse().map((b) => ({
        id: b.booking_id,
        amount: parseFloat(b.total_amount || 0),
        date: new Date(b.start_datetime).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
    }));
  }, [bookings]);

  const COLORS = ['#22c55e', '#3b82f6', '#ef4444', '#94a3b8']; // Green, Blue, Red, Slate

  return (
    <div className="min-h-screen bg-slate-50 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex justify-between items-center bg-white p-4 rounded-lg shadow-sm border">
            <div>
                <h1 className="text-2xl font-bold text-slate-800">Admin Console</h1>
                <p className="text-slate-500">Welcome, {employee?.first_name} ({employee?.job_role})</p>
            </div>
            <Button variant="outline" onClick={() => { localStorage.removeItem('employee'); navigate('/admin'); }}>
                <LogOut className="w-4 h-4 mr-2"/> Logout
            </Button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex space-x-1 bg-slate-100 p-1 rounded-lg w-fit">
            {['overview', 'fleet'].map(tab => (
                <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)} 
                    className={`px-4 py-2 text-sm font-medium rounded-md transition-all ${
                        activeTab === tab 
                        ? 'bg-white text-slate-900 shadow-sm' 
                        : 'text-slate-500 hover:text-slate-700'
                    }`}
                >
                    {tab === 'overview' && 'Overview'}
                    {tab === 'fleet' && 'Fleet Management'}
                </button>
            ))}
        </div>

        {/* ================= OVERVIEW TAB ================= */}
        {activeTab === 'overview' && (
            <div className="space-y-6">
                {/* KPI Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-sm font-medium text-slate-500">Recent Revenue</CardTitle>
                            <TrendingUp className="w-4 h-4 text-green-600"/>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">
                                ${bookings.reduce((sum, b) => sum + parseFloat(b.total_amount || 0), 0).toLocaleString()}
                            </div>
                            <p className="text-xs text-slate-400">Total from last 50 bookings</p>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-sm font-medium text-slate-500">Fleet Utilization</CardTitle>
                            <Activity className="w-4 h-4 text-blue-600"/>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">
                                {cars.length > 0 
                                    ? ((cars.filter(c => c.status === 'Booked').length / cars.length) * 100).toFixed(1)
                                    : 0}%
                            </div>
                            <p className="text-xs text-slate-400">{cars.filter(c => c.status === 'Booked').length} active bookings</p>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-sm font-medium text-slate-500">Total Fleet</CardTitle>
                            <Car className="w-4 h-4 text-slate-600"/>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">{cars.length}</div>
                            <p className="text-xs text-slate-400">Vehicles across all branches</p>
                        </CardContent>
                    </Card>
                </div>

                {/* Charts Area */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <Card className="col-span-2 lg:col-span-1">
                        <CardHeader>
                            <CardTitle>Revenue Trend</CardTitle>
                            <CardDescription>Daily volume from recent bookings</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="h-[300px] w-full">
                                <ResponsiveContainer width="100%" height="100%">
                                    <AreaChart data={revenueData}>
                                        <defs>
                                            <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                                <stop offset="5%" stopColor="#0f172a" stopOpacity={0.8}/>
                                                <stop offset="95%" stopColor="#0f172a" stopOpacity={0}/>
                                            </linearGradient>
                                        </defs>
                                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0"/>
                                        <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} minTickGap={30}/>
                                        <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(v) => `$${v}`}/>
                                        <Tooltip 
                                            contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                                            itemStyle={{ color: '#0f172a' }}
                                        />
                                        <Area type="monotone" dataKey="amount" stroke="#0f172a" fillOpacity={1} fill="url(#colorRevenue)" />
                                    </AreaChart>
                                </ResponsiveContainer>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="col-span-2 lg:col-span-1">
                        <CardHeader>
                            <CardTitle>Fleet Status</CardTitle>
                            <CardDescription>Current vehicle availability</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="h-[300px] w-full">
                                <ResponsiveContainer width="100%" height="100%">
                                    <RePieChart>
                                        <Pie
                                            data={fleetStatusData}
                                            cx="50%"                  
                                            cy="50%"                   
                                            innerRadius={60}
                                            outerRadius={80}
                                            paddingAngle={5}
                                            dataKey="value"
                                            isAnimationActive={false}  
                                        >
                                            {fleetStatusData.map((entry, index) => (
                                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                            ))}
                                        </Pie>
                                        <Tooltip />
                                        <Legend verticalAlign="bottom" height={36}/>
                                    </RePieChart>
                                </ResponsiveContainer>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        )}

        {/* ================= FLEET TAB ================= */}
        {activeTab === 'fleet' && (
            <div className="space-y-6">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Fleet Table */}
                    <Card className="lg:col-span-2">
                        <CardHeader>
                            <CardTitle>Vehicle Inventory</CardTitle>
                            <CardDescription>Manage status and maintenance logs</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="overflow-auto max-h-[500px]">
                                <table className="w-full text-sm text-left">
                                    <thead className="bg-slate-100 text-slate-600 sticky top-0">
                                        <tr>
                                            <th className="p-3">ID</th>
                                            <th className="p-3">Vehicle</th>
                                            <th className="p-3">Plate</th>
                                            <th className="p-3">Branch</th>
                                            <th className="p-3">Status</th>
                                            <th className="p-3">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y">
                                        {cars.map(car => (
                                            <tr key={car.car_id} className="hover:bg-slate-50">
                                                <td className="p-3 font-mono text-slate-500">#{car.car_id}</td>
                                                <td className="p-3 font-medium">{car.car_make} {car.car_model}</td>
                                                <td className="p-3">{car.license_plate}</td>
                                                <td className="p-3 text-slate-500">{car.branch_name}</td>
                                                <td className="p-3">{getStatusBadge(car.status)}</td>
                                                <td className="p-3">
                                                    {car.status !== 'Maintenance' && car.status !== 'Retired' && (
                                                        <Button size="sm" variant="outline" onClick={() => setSelectedCar(car)}>
                                                            <Wrench className="w-3 h-3 mr-1"/> Service
                                                        </Button>
                                                    )}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Side Panel: Branch Chart & Maintenance Form */}
                    <div className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Vehicles by Branch</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="h-[200px]">
                                    <ResponsiveContainer width="100%" height="100%">
                                        <BarChart data={branchData} layout="vertical">
                                            <CartesianGrid strokeDasharray="3 3" horizontal={true} vertical={false} />
                                            <XAxis type="number" hide />
                                            <YAxis dataKey="name" type="category" width={100} fontSize={12} tickLine={false} axisLine={false} />
                                            <Tooltip cursor={{fill: 'transparent'}} />
                                            <Bar dataKey="cars" fill="#3b82f6" radius={[0, 4, 4, 0]} barSize={20} />
                                        </BarChart>
                                    </ResponsiveContainer>
                                </div>
                            </CardContent>
                        </Card>

                        <Card className="h-fit border-red-100">
                            <CardHeader className="bg-red-50/50">
                                <CardTitle className="text-red-700 text-base">Log Maintenance</CardTitle>
                            </CardHeader>
                            <CardContent className="pt-4">
                                {!selectedCar ? (
                                    <div className="text-center text-slate-400 py-4 text-sm">Select a vehicle from the table to log service.</div>
                                ) : (
                                    <form onSubmit={handleMaintenanceSubmit} className="space-y-3">
                                        <div className="p-2 bg-slate-100 rounded text-xs">
                                            <span className="font-bold">Vehicle:</span> {selectedCar.car_make} ({selectedCar.license_plate})
                                        </div>
                                        <Input type="datetime-local" className="h-8 text-xs" required onChange={e => setMaintForm({...maintForm, date_in: e.target.value})} />
                                        <Input type="number" placeholder="Cost ($)" className="h-8 text-xs" required onChange={e => setMaintForm({...maintForm, cost: e.target.value})} />
                                        <Input placeholder="Description" className="h-8 text-xs" required onChange={e => setMaintForm({...maintForm, description: e.target.value})} />
                                        <div className="flex gap-2">
                                            <Button type="button" variant="ghost" size="sm" onClick={() => setSelectedCar(null)} className="flex-1 h-8">Cancel</Button>
                                            <Button type="submit" size="sm" className="flex-1 bg-red-600 hover:bg-red-700 h-8">Log</Button>
                                        </div>
                                    </form>
                                )}
                            </CardContent>
                        </Card>
                    </div>
                </div>
            </div>
        )}
      </div>
    </div>
  );
};

export default AdminDashboardPage;