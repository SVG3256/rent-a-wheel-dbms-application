import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { signupUser } from '../api/client';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '../components/ui/card';
import { UserPlus } from 'lucide-react';

const SignupPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    first_name: '', last_name: '', email: '',
    contact_no: '', license_no: '', dob: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await signupUser(formData);
      navigate('/'); // Redirect to login on success
    } catch (err) {
      setError(err.response?.data?.error || 'Signup failed. Email or License might exist.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 p-4">
      <Card className="w-full max-w-lg shadow-xl">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-2">
            <div className="p-3 bg-primary/10 rounded-full">
              <UserPlus className="w-6 h-6 text-primary" />
            </div>
          </div>
          <CardTitle className="text-2xl">Create Account</CardTitle>
          <CardDescription>Join RentAWheel to start driving.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">First Name</label>
                <Input name="first_name" onChange={handleChange} required />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Last Name</label>
                <Input name="last_name" onChange={handleChange} required />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Email</label>
              <Input type="email" name="email" onChange={handleChange} required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Contact No</label>
                <Input name="contact_no" placeholder="e.g. 617-555-0199" onChange={handleChange} required />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Date of Birth</label>
                <Input type="date" name="dob" onChange={handleChange} required />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Driver License No</label>
              <Input name="license_no" onChange={handleChange} required />
            </div>

            {error && <p className="text-sm text-red-500 font-medium">{error}</p>}

            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Creating Account...' : 'Sign Up'}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex flex-col gap-4 text-center border-t pt-6 bg-slate-50/50">
    <p className="text-sm text-gray-500">
        Don't have an account? <Link to="/signup" className="text-primary font-semibold hover:underline">Sign up</Link>
    </p>
    
    {/* --- ADMIN  LINK --- */}
    <Link to="/admin" className="text-xs text-slate-400 hover:text-slate-600 mt-2">
        Employee Portal Access
    </Link>
</CardFooter>
      </Card>
    </div>
  );
};

export default SignupPage;