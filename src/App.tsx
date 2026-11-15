import { useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { Activity, AlertTriangle, BookOpen, CalendarCheck, GraduationCap, LayoutDashboard, LogOut, Plus, Search, ShieldCheck, Users } from 'lucide-react';
import { supabase, isSupabaseConfigured } from './lib/supabase';

type Profile={id:string;full_name:string;role:'admin'|'teacher'|'advisor'|'student';account_status:string};
type Student={id:string;full_name:string;roll_number:string;class_level:string;section:string;academic_year:number};
const menu=[['overview','Overview',LayoutDashboard],['students','Students',Users],['academics','Academics',BookOpen],['attendance','Attendance',CalendarCheck],['risk','Risk monitoring',Activity]] as const;
export default function App(){
 const [session,setSession]=useState<any>(null),[profile,setProfile]=useState<Profile|null>(null),[loading,setLoading]=useState(true),[page,setPage]=useState('overview'),[students,setStudents]=useState<Student[]>([]),[error,setError]=useState(''),[mode,setMode]=useState<'login'|'signup'>('login'),[showAdd,setShowAdd]=useState(false),[query,setQuery]=useState('');
 useEffect(()=>{
  if(!supabase){setLoading(false);return}
  let mounted=true;
  const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,nextSession)=>{
   if(!mounted)return;
   setSession(nextSession);
   if(!nextSession){setProfile(null);setLoading(false)}
  });
  supabase.auth.getSession().then(({data,error})=>{
   if(!mounted)return;
   if(error)setError(error.message);
   setSession(data.session);
   if(!data.session)setLoading(false);
  }).catch((err:unknown)=>{
   if(!mounted)return;
   setError(err instanceof Error?err.message:'Unable to check your sign-in session.');
   setLoading(false);
  });
  return()=>{mounted=false;subscription.unsubscribe()};
 },[]);
 useEffect(()=>{
  if(!supabase)return;
  if(!session){setProfile(null);setLoading(false);return}
  let active=true;
  setLoading(true);
  supabase.from('profiles').select('id,full_name,role,account_status').eq('id',session.user.id).maybeSingle().then(({data,error})=>{
   if(!active)return;
   if(error)setError(error.message);
   setProfile(data as Profile|null);
   setLoading(false);
  }).catch((err:unknown)=>{
   if(!active)return;
   setError(err instanceof Error?err.message:'Unable to load your school profile.');
   setLoading(false);
  });
  return()=>{active=false};
 },[session]);
 async function loadStudents(){if(!supabase||!profile)return;let q=supabase.from('students').select('id,full_name,roll_number,class_level,section,academic_year').order('class_level').order('roll_number');if(profile.role==='student')q=q.eq('profile_id',profile.id);const {data,error}=await q;if(error)setError(error.message);else setStudents((data||[]) as Student[])}
 useEffect(()=>{loadStudents()},[profile]);
 async function auth(e:FormEvent<HTMLFormElement>){e.preventDefault();setError('');const f=new FormData(e.currentTarget);if(!supabase)return;const email=String(f.get('email')),password=String(f.get('password'));if(mode==='login'){const {error}=await supabase.auth.signInWithPassword({email,password});if(error)setError(error.message)}else{const {error}=await supabase.auth.signUp({email,password,options:{data:{full_name:String(f.get('name'))}}});if(error)setError(error.message);else setError('Account created. Check your email if confirmation is enabled. Your account will need school approval.')}}
 if(!isSupabaseConfigured)return <div className="center"><Logo/><h1>Connect your school portal</h1><p>Copy .env.example to .env and add your Supabase URL and publishable key. Then restart the development server.</p></div>;
 if(loading)return <div className="center">Loading your school portal…</div>;
 if(!session)return <div className="auth"><div className="auth-side"><Logo/><div><small>WELCOME TO A BETTER SCHOOL EXPERIENCE</small><h1>Every student.<br/>Every possibility.</h1><p>One connected space for school communities to learn, grow and thrive.</p></div></div><form className="auth-form" onSubmit={auth}><small>EDUCARE SCHOOL PORTAL</small><h2>{mode==='login'?'Welcome back':'Create your account'}</h2><p>{mode==='login'?'Sign in to continue.':'Student self-registration.'}</p>{mode==='signup'&&<label>Full name<input name="name" required placeholder="Your full name"/></label>}<label>Email<input name="email" type="email" required placeholder="you@school.edu"/></label><label>Password<input name="password" type="password" minLength={6} required placeholder="At least 6 characters"/></label>{error&&<div className="error">{error}</div>}<button className="primary">{mode==='login'?'Sign in':'Create account'}</button><p className="toggle">{mode==='login'?'New here?':'Already registered?'} <button type="button" onClick={()=>{setMode(mode==='login'?'signup':'login');setError('')}}>{mode==='login'?'Create account':'Sign in'}</button></p></form></div>;
 if(!profile)return <div className="center"><ShieldCheck/><h2>Profile not ready</h2><p>Ask your school administrator to check your account profile.</p><button onClick={()=>supabase?.auth.signOut()}>Sign out</button></div>;
 if(profile.account_status!=='Approved')return <div className="center"><ShieldCheck/><h2>Waiting for school approval</h2><p>Your account is pending approval by the school administrator.</p><button onClick={()=>supabase?.auth.signOut()}>Sign out</button></div>;
 const visible=students.filter(s=>[s.full_name,s.roll_number,s.class_level,s.section].join(' ').toLowerCase().includes(query.toLowerCase()));
 return <div className="layout"><aside><Logo/><p className="side-label">SCHOOL WORKSPACE</p>{menu.filter(([id])=>id!=='students'||profile.role!=='student').map(([id,label,Icon])=><button key={id} className={page===id?'nav active':'nav'} onClick={()=>setPage(id)}><Icon size={18}/>{label}</button>)}<div className="user"><b>{profile.full_name}</b><small>{profile.role}</small><button onClick={()=>supabase?.auth.signOut()}><LogOut size={15}/> Sign out</button></div></aside><main><header><span>School portal / {page}</span><span className="role">{profile.role}</span></header><section><div className="heading"><div><small>YOUR SCHOOL, IN SYNC</small><h1>{page==='overview'?'Good day, '+profile.full_name.split(' ')[0]:menu.find(m=>m[0]===page)?.[1]}</h1><p>Manage learning, student progress and school support.</p></div>{page==='students'&&profile.role==='admin'&&<button className="primary" onClick={()=>setShowAdd(true)}><Plus size={16}/> Add student</button>}</div>{error&&<p className="error">{error}</p>}
 {page==='overview'&&<><div className="banner"><div><small>EDUCARE • SCHOOL MANAGEMENT</small><h2>A clearer view of every learner.</h2><p>Bring student information, academic progress and support into one place.</p></div><GraduationCap size={76}/></div><div className="stats"><article><Users/><small>Total students</small><strong>{students.length}</strong></article><article><BookOpen/><small>Academic records</small><strong>—</strong></article><article><CalendarCheck/><small>Attendance</small><strong>—</strong></article><article><AlertTriangle/><small>Students to review</small><strong>—</strong></article></div><div className="panel"><h3>Student-first by design</h3><p>Academic indicators should guide supportive conversations—not label students. Staff should review each student's context before taking action.</p></div></>}
 {page==='students'&&<div className="panel"><div className="panel-head"><h3>Student directory</h3><div className="search"><Search size={16}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search students"/></div></div><div className="table-wrap"><table><thead><tr><th>STUDENT</th><th>ROLL NO.</th><th>CLASS</th><th>SECTION</th><th>YEAR</th></tr></thead><tbody>{visible.map(s=><tr key={s.id}><td>{s.full_name}</td><td>{s.roll_number}</td><td>{s.class_level}</td><td>{s.section}</td><td>{s.academic_year}</td></tr>)}</tbody></table>{visible.length===0&&<p className="muted">No student records found.</p>}</div></div>}
 {page!=='overview'&&page!=='students'&&<div className="panel module"><div className="module-icon">{page==='academics'?<BookOpen/>:page==='attendance'?<CalendarCheck/>:<Activity/>}</div><h2>{menu.find(m=>m[0]===page)?.[1]}</h2><p>{page==='academics'?'Subject-wise marks, grades and academic progress.':page==='attendance'?'Daily attendance, history and monthly summaries.':'Staff-reviewed low, medium and high support flags.'}</p><p className="muted">This module is scaffolded in the database. Its data-entry and reporting screens are the next implementation step.</p></div>}</section></main>
 {showAdd&&<AddStudent close={()=>setShowAdd(false)} save={async(v)=>{const {error}=await supabase!.from('students').insert(v);if(error)throw error;await loadStudents();setShowAdd(false)}}/>}</div>
}
function Logo(){return <div className="logo"><span><GraduationCap size={21}/></span> edu<b>care</b></div>}
function AddStudent({close,save}:{close:()=>void;save:(v:any)=>Promise<void>}){const [busy,setBusy]=useState(false),[err,setErr]=useState('');async function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();setBusy(true);const f=new FormData(e.currentTarget);try{await save({full_name:f.get('name'),roll_number:f.get('roll'),class_level:f.get('class'),section:f.get('section'),academic_year:Number(f.get('year'))})}catch(e:any){setErr(e.message||'Unable to save')}finally{setBusy(false)}}return <div className="overlay"><form className="modal" onSubmit={submit}><h2>Add student</h2><label>Full name<input name="name" required/></label><div className="row"><label>Roll number<input name="roll" required/></label><label>Class<input name="class" required/></label></div><div className="row"><label>Section<input name="section" required/></label><label>Academic year<input name="year" type="number" defaultValue={new Date().getFullYear()} required/></label></div>{err&&<p className="error">{err}</p>}<div className="actions"><button type="button" onClick={close}>Cancel</button><button className="primary" disabled={busy}>{busy?'Saving…':'Save student'}</button></div></form></div>}
