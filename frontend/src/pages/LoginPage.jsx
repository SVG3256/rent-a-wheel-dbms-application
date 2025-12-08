import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { loginUser } from '../api/client';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '../components/ui/card';
import { Car, ShieldCheck } from 'lucide-react';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const data = await loginUser(email);
      localStorage.setItem('user', JSON.stringify(data.user));
      navigate('/dashboard'); 
    } catch (err) {
      setError('User not found. Please sign up first.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 p-4">
      <Card className="w-full max-w-md shadow-xl border-t-4 border-primary">
        <CardHeader className="text-center space-y-2">
          <div className="flex justify-center mb-4">
            <div className="p-4 bg-white rounded-full shadow-sm border">
              <Car className="w-10 h-10 text-primary" />
            </div>
          </div>
          <CardTitle className="text-3xl font-bold tracking-tight text-slate-800">RentAWheel</CardTitle>
          <CardDescription>Welcome back! Enter your email to continue.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
                <label className="text-sm font-medium text-slate-700">Email Address</label>
                <Input
                type="email" 
                placeholder="john.doe@example.com" 
                value={email} 
                onChange={(e) => setEmail(e.target.value)} 
                required 
                className="h-11"
                />
            </div>
            {error && <div className="p-3 rounded-md bg-red-50 text-red-500 text-sm border border-red-200">{error}</div>}
            <Button type="submit" className="w-full h-11 text-base" disabled={loading}>
              {loading ? 'Logging in...' : 'Login'}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex flex-col gap-4 text-center border-t pt-6 bg-slate-50/50">
            <p className="text-sm text-gray-500">
                Don't have an account? <Link to="/signup" className="text-primary font-semibold hover:underline">Sign up</Link>
            </p>
            
            {/* --- ADMIN LINK --- */}
            <Link to="/admin" className="flex items-center justify-center gap-2 text-xs text-slate-400 hover:text-slate-600 transition-colors mt-2">
                <ShieldCheck className="w-3 h-3" />
                Employee Portal Access
            </Link>
        </CardFooter>
      </Card>
    </div>
  );
};

export default LoginPage;