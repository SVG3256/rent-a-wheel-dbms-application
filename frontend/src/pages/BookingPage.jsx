import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchStaticData, searchCars, createBooking, makePayment } from '../api/client';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { DollarSign, CheckCircle, ArrowLeft } from 'lucide-react';

const BookingPage = () => {
  const navigate = useNavigate();
  const user = JSON.parse(localStorage.getItem('user'));
  
  // Steps: 1=Search, 2=Select Car, 3=Options/Confirm, 4=Payment, 5=Success
  const [step, setStep] = useState(1); 
  
  const [staticData, setStaticData] = useState({ branches: [], insurance: [], promotions: [] });
  const [search, setSearch] = useState({ pickupBranch: '', dropoffBranch: '', start: '', end: '' });
  const [cars, setCars] = useState([]);
  const [selectedCar, setSelectedCar] = useState(null);
  
  
  const [options, setOptions] = useState({ insuranceId: '1', promoCode: '' });
  
  const [bookingResult, setBookingResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!user) navigate('/');
    fetchStaticData().then(data => {
        setStaticData(data);
        // Automatically select 'Basic' insurance by default
        const basicPolicy = data.insurance.find(i => i.package_name === 'Basic');
        if (basicPolicy) {
            setOptions(prev => ({ ...prev, insuranceId: String(basicPolicy.policy_id) }));
        }
    }).catch(console.error);
  }, []);

  // Format date for SQL: YYYY-MM-DD HH:MM:SS
  const toSqlDate = (dateStr) => dateStr.replace('T', ' ') + ':00';

  const handleSearch = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await searchCars({
        branch_id: search.pickupBranch,
        start_date: toSqlDate(search.start),
        end_date: toSqlDate(search.end)
      });
      setCars(res);
      setStep(2);
    } catch (err) { setError('Search failed. Please try again.'); } 
    finally { setLoading(false); }
  };

  const calculateTotal = () => {
    if (!selectedCar) return 0;
    const s = new Date(search.start);
    const e = new Date(search.end);
    const days = Math.max(1, Math.ceil((e - s) / (1000 * 60 * 60 * 24)));
    
    let daily = parseFloat(selectedCar.daily_rate);
    // Add insurance cost
    if (options.insuranceId) {
        const ins = staticData.insurance.find(i => String(i.policy_id) === options.insuranceId);
        if (ins) daily += parseFloat(ins.daily_cost);
    }
    
    let total = daily * days;
    
    // Apply Promo
    if (options.promoCode) {
        const promo = staticData.promotions.find(p => p.promo_code === options.promoCode);
        if (promo) total = total * ((100 - parseFloat(promo.discount_perc)) / 100);
    }
    return total.toFixed(2);
  };

  const handleCreateBooking = async () => {
    setLoading(true);
    setError('');
    try {
        const payload = {
            cust_id: user.cust_id,
            car_id: selectedCar.car_id, 
            car_make: selectedCar.car_make,
            car_model: selectedCar.car_model,
            year: selectedCar.year,
            pickup_branch_id: search.pickupBranch,
            dropoff_branch_id: search.dropoffBranch,
            start_datetime: toSqlDate(search.start),
            end_datetime: toSqlDate(search.end),
            insurance_policy_id: options.insuranceId,
            promo_code: options.promoCode || null
        };
        const res = await createBooking(payload);
        setBookingResult({ id: res.booking_id, amount: calculateTotal() });
        setStep(4);
    } catch (err) {
        setError(err.response?.data?.error || 'Booking creation failed.');
    } finally { setLoading(false); }
  };

  const handlePay = async () => {
    setLoading(true);
    try {
        await makePayment({
            booking_id: bookingResult.id,
            amount: bookingResult.amount,
            payment_mode: 'card'
        });
        setStep(5);
    } catch (err) { setError('Payment failed.'); }
    finally { setLoading(false); }
  };

  // --- Step Components ---
  
  // 1. Search Bar
  const renderSearch = () => (
    <Card>
        <CardHeader><CardTitle>Search Availability</CardTitle></CardHeader>
        <CardContent>
            <form onSubmit={handleSearch} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="text-sm font-medium mb-1 block">Pickup Branch</label>
                        <Select onValueChange={(v) => setSearch({...search, pickupBranch: v})}>
                            <SelectTrigger><SelectValue placeholder="Select Branch" /></SelectTrigger>
                            <SelectContent>
                                {staticData.branches.map(b => <SelectItem key={b.branch_id} value={String(b.branch_id)}>{b.branch_name}</SelectItem>)}
                            </SelectContent>
                        </Select>
                    </div>
                    <div>
                        <label className="text-sm font-medium mb-1 block">Dropoff Branch</label>
                        <Select onValueChange={(v) => setSearch({...search, dropoffBranch: v})}>
                            <SelectTrigger><SelectValue placeholder="Select Branch" /></SelectTrigger>
                            <SelectContent>
                                {staticData.branches.map(b => <SelectItem key={b.branch_id} value={String(b.branch_id)}>{b.branch_name}</SelectItem>)}
                            </SelectContent>
                        </Select>
                    </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                        <label className="text-sm font-medium">Pickup Date</label>
                        <Input type="datetime-local" onChange={(e) => setSearch({...search, start: e.target.value})} required />
                    </div>
                    <div className="space-y-1">
                        <label className="text-sm font-medium">Return Date</label>
                        <Input type="datetime-local" onChange={(e) => setSearch({...search, end: e.target.value})} required />
                    </div>
                </div>
                {error && <p className="text-red-500 text-sm">{error}</p>}
                <Button type="submit" className="w-full" disabled={loading}>{loading ? 'Checking...' : 'Find Cars'}</Button>
            </form>
        </CardContent>
    </Card>
  );

  // 2. Car Selection
  const renderCarSelect = () => (
    <div className="space-y-4">
        <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold">Select a Vehicle</h2>
            <Button variant="ghost" onClick={() => setStep(1)}><ArrowLeft className="w-4 h-4 mr-2"/> Modify Search</Button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {cars.map(car => (
                <Card key={car.car_id} className="cursor-pointer hover:border-primary transition-colors" onClick={() => { setSelectedCar(car); setStep(3); }}>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-lg">{car.car_make} {car.car_model}</CardTitle>
                        <CardDescription>{car.year} • {car.category}</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="flex justify-between items-center mt-2">
                            <span className="text-sm bg-secondary px-2 py-1 rounded">License: {car.license_plate}</span>
                            <span className="font-bold text-lg text-primary">${car.daily_rate}<span className="text-sm font-normal text-gray-500">/day</span></span>
                        </div>
                    </CardContent>
                </Card>
            ))}
            {cars.length === 0 && <p className="text-gray-500 col-span-full text-center py-10">No cars available for these dates and location.</p>}
        </div>
    </div>
  );

  // 3. Confirm Details
  const renderConfirm = () => (
    <Card className="max-w-xl mx-auto">
        <CardHeader>
            <CardTitle>Customize & Confirm</CardTitle>
            <CardDescription>{selectedCar.car_make} {selectedCar.car_model}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
            <div className="p-4 bg-slate-50 rounded border space-y-2">
                <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Pickup</span>
                    <span className="font-medium">{search.start.replace('T', ' ')}</span>
                </div>
                <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Return</span>
                    <span className="font-medium">{search.end.replace('T', ' ')}</span>
                </div>
            </div>

            <div className="space-y-2">
                <label className="text-sm font-medium">Insurance Coverage (Required)</label>
                
                <Select value={options.insuranceId} onValueChange={(v) => setOptions({...options, insuranceId: v})}>
                    <SelectTrigger><SelectValue placeholder="Select Insurance" /></SelectTrigger>
                    <SelectContent>
                        {staticData.insurance.map(i => (
                            <SelectItem key={i.policy_id} value={String(i.policy_id)}>{i.package_name} (+${i.daily_cost}/day)</SelectItem>
                        ))}
                    </SelectContent>
                </Select>
            </div>

            <div className="space-y-2">
                <label className="text-sm font-medium">Promo Code</label>
                <Input placeholder="Enter code (e.g. WELCOME10)" onChange={(e) => setOptions({...options, promoCode: e.target.value})} />
            </div>

            <div className="pt-4 border-t flex justify-between items-end">
                <div>
                    <p className="text-sm text-gray-500">Estimated Total</p>
                    <p className="text-3xl font-bold text-primary">${calculateTotal()}</p>
                </div>
                <Button onClick={handleCreateBooking} disabled={loading} size="lg">
                    {loading ? 'Processing...' : 'Confirm Booking'}
                </Button>
            </div>
            {error && <p className="text-red-500 text-sm mt-2 p-2 bg-red-50 border border-red-200 rounded">{error}</p>}
        </CardContent>
    </Card>
  );

  // 4. Payment
  const renderPayment = () => (
    <Card className="max-w-md mx-auto text-center">
        <CardHeader>
            <div className="mx-auto w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-4">
                <DollarSign className="text-blue-600" />
            </div>
            <CardTitle>Secure Payment</CardTitle>
            <CardDescription>Booking Reference #{bookingResult?.id}</CardDescription>
        </CardHeader>
        <CardContent>
            <div className="py-6">
                <p className="text-sm text-gray-500 mb-2">Total Amount Due</p>
                <p className="text-4xl font-bold text-slate-900">${bookingResult?.amount}</p>
            </div>
            {error && <p className="text-red-500 text-sm mb-4">{error}</p>}
            <Button className="w-full" size="lg" onClick={handlePay} disabled={loading}>
                {loading ? 'Processing...' : `Pay $${bookingResult?.amount} Now`}
            </Button>
        </CardContent>
    </Card>
  );

  // 5. Success
  const renderSuccess = () => (
    <Card className="max-w-md mx-auto text-center border-green-500 border-t-4">
        <CardContent className="pt-10 pb-10 space-y-4">
            <CheckCircle className="w-16 h-16 text-green-500 mx-auto" />
            <h2 className="text-2xl font-bold">Booking Confirmed!</h2>
            <p className="text-gray-500">Your car is reserved and ready for pickup.</p>
            <div className="pt-6">
                <Button onClick={() => navigate('/dashboard')} variant="outline">Go to Dashboard</Button>
            </div>
        </CardContent>
    </Card>
  );

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
        <div className="max-w-5xl mx-auto">
            {step < 5 && (
                <div className="flex justify-center mb-8 space-x-2 text-sm">
                    {[1,2,3,4].map(i => (
                        <div key={i} className={`px-3 py-1 rounded-full ${step === i ? 'bg-primary text-white' : 'bg-gray-200 text-gray-500'}`}>
                            Step {i}
                        </div>
                    ))}
                </div>
            )}
            
            {step === 1 && renderSearch()}
            {step === 2 && renderCarSelect()}
            {step === 3 && renderConfirm()}
            {step === 4 && renderPayment()}
            {step === 5 && renderSuccess()}
        </div>
    </div>
  );
};

export default BookingPage;