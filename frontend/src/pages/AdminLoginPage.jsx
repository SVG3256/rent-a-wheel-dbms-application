import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { loginEmployee } from '../api/client';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/ui/card';
import { ShieldCheck } from 'lucide-react';

const AdminLoginPage = () => {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const data = await loginEmployee(email);
      localStorage.setItem('employee', JSON.stringify(data.employee));
      navigate('/admin/dashboard');
    } catch (err) {
      setError('Invalid employee email.');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-900 p-4">
      <Card className="w-full max-w-md border-slate-700 bg-slate-800 text-white">
        <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
                <ShieldCheck className="w-12 h-12 text-blue-400" />
            </div>
          <CardTitle className="text-2xl">Employee Portal</CardTitle>
          <CardDescription className="text-slate-400">Restricted Access</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
                <label className="text-sm font-medium text-slate-300">Work Email</label>
                <Input 
                    className="bg-slate-700 border-slate-600 text-white placeholder:text-slate-500"
                    placeholder="alice.w@rentawheel.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                />
            </div>
            {error && <p className="text-red-400 text-sm">{error}</p>}
            <Button type="submit" className="w-full bg-blue-600 hover:bg-blue-700">Login to Console</Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
};

export default AdminLoginPage;