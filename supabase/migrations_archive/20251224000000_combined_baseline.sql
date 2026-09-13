
-- ============================================
-- Source: 20251224071107_2bbd0031-6ca3-4e54-bab6-112f72c631cf.sql
-- ============================================

-- Create teams table
CREATE TABLE public.teams (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  short_name TEXT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create tournaments table
CREATE TABLE public.tournaments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  sport TEXT NOT NULL DEFAULT 'Cricket',
  season TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create matches table
CREATE TABLE public.matches (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  team_a_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  team_b_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  match_number INTEGER NOT NULL DEFAULT 1,
  match_date TEXT NOT NULL,
  match_time TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'live', 'completed')),
  venue TEXT,
  score_a TEXT,
  score_b TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create profiles table for admins
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Teams policies (public read, admin write)
CREATE POLICY "Teams are viewable by everyone" 
  ON public.teams FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can insert teams" 
  ON public.teams FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update teams" 
  ON public.teams FOR UPDATE 
  TO authenticated 
  USING (true);

CREATE POLICY "Authenticated users can delete teams" 
  ON public.teams FOR DELETE 
  TO authenticated 
  USING (true);

-- Tournaments policies (public read, admin write)
CREATE POLICY "Tournaments are viewable by everyone" 
  ON public.tournaments FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can insert tournaments" 
  ON public.tournaments FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update tournaments" 
  ON public.tournaments FOR UPDATE 
  TO authenticated 
  USING (true);

CREATE POLICY "Authenticated users can delete tournaments" 
  ON public.tournaments FOR DELETE 
  TO authenticated 
  USING (true);

-- Matches policies (public read, admin write)
CREATE POLICY "Matches are viewable by everyone" 
  ON public.matches FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can insert matches" 
  ON public.matches FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update matches" 
  ON public.matches FOR UPDATE 
  TO authenticated 
  USING (true);

CREATE POLICY "Authenticated users can delete matches" 
  ON public.matches FOR DELETE 
  TO authenticated 
  USING (true);

-- Profiles policies
CREATE POLICY "Profiles are viewable by owner" 
  ON public.profiles FOR SELECT 
  TO authenticated 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" 
  ON public.profiles FOR INSERT 
  TO authenticated 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  TO authenticated 
  USING (auth.uid() = user_id);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_teams_updated_at
  BEFORE UPDATE ON public.teams
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tournaments_updated_at
  BEFORE UPDATE ON public.tournaments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_matches_updated_at
  BEFORE UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create indexes for better performance
CREATE INDEX idx_matches_tournament_id ON public.matches(tournament_id);
CREATE INDEX idx_matches_team_a_id ON public.matches(team_a_id);
CREATE INDEX idx_matches_team_b_id ON public.matches(team_b_id);
CREATE INDEX idx_matches_status ON public.matches(status);
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);

-- ============================================
-- Source: 20251224073736_0d9691a4-5c5b-4fbe-84d1-982d483745b4.sql
-- ============================================

-- Add new columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS match_link text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS match_duration_minutes integer DEFAULT 180,
ADD COLUMN IF NOT EXISTS match_start_time timestamp with time zone DEFAULT NULL;

-- Add logo_url to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS logo_url text DEFAULT NULL;

-- Create banners table
CREATE TABLE IF NOT EXISTS public.banners (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  image_url text NOT NULL,
  link_url text,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS for banners
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

-- Public can view active banners
CREATE POLICY "Active banners are viewable by everyone" 
ON public.banners 
FOR SELECT 
USING (is_active = true);

-- Authenticated users can manage banners
CREATE POLICY "Authenticated users can insert banners" 
ON public.banners 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Authenticated users can update banners" 
ON public.banners 
FOR UPDATE 
USING (true);

CREATE POLICY "Authenticated users can delete banners" 
ON public.banners 
FOR DELETE 
USING (true);

-- Create trigger for banners updated_at
CREATE TRIGGER update_banners_updated_at
BEFORE UPDATE ON public.banners
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- Source: 20251224082351_9d990dc0-8410-49af-adcf-b6e55364f17c.sql
-- ============================================

-- Create sports table for managing sport types with icons
CREATE TABLE public.sports (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on sports
ALTER TABLE public.sports ENABLE ROW LEVEL SECURITY;

-- Sports are viewable by everyone
CREATE POLICY "Sports are viewable by everyone" 
ON public.sports 
FOR SELECT 
USING (true);

-- Only admins can manage sports (will use has_role function)
CREATE POLICY "Admins can insert sports" 
ON public.sports 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Admins can update sports" 
ON public.sports 
FOR UPDATE 
USING (true);

CREATE POLICY "Admins can delete sports" 
ON public.sports 
FOR DELETE 
USING (true);

-- Add trigger for updated_at
CREATE TRIGGER update_sports_updated_at
BEFORE UPDATE ON public.sports
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add new columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS is_priority BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS match_label TEXT,
ADD COLUMN IF NOT EXISTS sport_id UUID REFERENCES public.sports(id);

-- Make tournament_id nullable (optional)
ALTER TABLE public.matches 
ALTER COLUMN tournament_id DROP NOT NULL;

-- Create enum for user roles
CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');

-- Create user_roles table for secure role management
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

-- Enable RLS on user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create security definer function to check roles (prevents recursion)
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- RLS policies for user_roles
CREATE POLICY "Users can view their own roles"
ON public.user_roles
FOR SELECT
USING (auth.uid() = user_id);

-- Insert some default sports
INSERT INTO public.sports (name, icon_url) VALUES 
  ('Cricket', NULL),
  ('Football', NULL),
  ('Tennis', NULL),
  ('Basketball', NULL),
  ('Hockey', NULL)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- Source: 20251224091903_177ddd4a-b334-4841-9a05-c0100d6187fa.sql
-- ============================================

-- Create site_settings table for website configuration
CREATE TABLE public.site_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  site_name text NOT NULL DEFAULT 'Live Sports',
  site_title text NOT NULL DEFAULT 'Live Sports - Watch Live Matches',
  site_description text DEFAULT 'Watch live sports matches online. Get live scores, schedules and streaming links for Cricket, Football, Tennis and more.',
  site_keywords text DEFAULT 'live sports, live streaming, cricket, football, tennis, live scores',
  logo_url text,
  favicon_url text,
  og_image_url text,
  footer_text text DEFAULT 'All rights reserved.',
  google_analytics_id text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Site settings are viewable by everyone"
ON public.site_settings FOR SELECT USING (true);

CREATE POLICY "Admins can update site settings"
ON public.site_settings FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert site settings"
ON public.site_settings FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Insert default settings
INSERT INTO public.site_settings (site_name) VALUES ('Live Sports');

-- Create streaming_servers table for multiple streaming links per match
CREATE TABLE public.streaming_servers (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id uuid NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  server_name text NOT NULL,
  server_url text NOT NULL,
  server_type text NOT NULL DEFAULT 'iframe', -- 'iframe', 'm3u8', 'embed'
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.streaming_servers ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Streaming servers are viewable by everyone"
ON public.streaming_servers FOR SELECT USING (true);

CREATE POLICY "Admins can manage streaming servers"
ON public.streaming_servers FOR ALL USING (public.has_role(auth.uid(), 'admin'));

-- Add new columns to matches table for SEO-friendly match pages
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS slug text UNIQUE,
ADD COLUMN IF NOT EXISTS page_type text DEFAULT 'redirect', -- 'redirect' or 'page'
ADD COLUMN IF NOT EXISTS seo_title text,
ADD COLUMN IF NOT EXISTS seo_description text;

-- Create trigger for updated_at on new tables
CREATE TRIGGER update_site_settings_updated_at
BEFORE UPDATE ON public.site_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_streaming_servers_updated_at
BEFORE UPDATE ON public.streaming_servers
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- Source: 20251224095646_0f3b6ee6-5d24-48c7-8d6b-8d69772f410d.sql
-- ============================================

-- Fix CLIENT_SIDE_AUTH: Update RLS policies to require admin role for write operations

-- Drop existing permissive policies for teams
DROP POLICY IF EXISTS "Authenticated users can delete teams" ON public.teams;
DROP POLICY IF EXISTS "Authenticated users can insert teams" ON public.teams;
DROP POLICY IF EXISTS "Authenticated users can update teams" ON public.teams;

-- Create new admin-only policies for teams
CREATE POLICY "Admins can delete teams" 
ON public.teams 
FOR DELETE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert teams" 
ON public.teams 
FOR INSERT 
TO authenticated
WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update teams" 
ON public.teams 
FOR UPDATE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

-- Drop existing permissive policies for tournaments
DROP POLICY IF EXISTS "Authenticated users can delete tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Authenticated users can insert tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Authenticated users can update tournaments" ON public.tournaments;

-- Create new admin-only policies for tournaments
CREATE POLICY "Admins can delete tournaments" 
ON public.tournaments 
FOR DELETE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert tournaments" 
ON public.tournaments 
FOR INSERT 
TO authenticated
WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update tournaments" 
ON public.tournaments 
FOR UPDATE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

-- Drop existing permissive policies for matches
DROP POLICY IF EXISTS "Authenticated users can delete matches" ON public.matches;
DROP POLICY IF EXISTS "Authenticated users can insert matches" ON public.matches;
DROP POLICY IF EXISTS "Authenticated users can update matches" ON public.matches;

-- Create new admin-only policies for matches
CREATE POLICY "Admins can delete matches" 
ON public.matches 
FOR DELETE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert matches" 
ON public.matches 
FOR INSERT 
TO authenticated
WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update matches" 
ON public.matches 
FOR UPDATE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

-- Drop existing permissive policies for sports
DROP POLICY IF EXISTS "Admins can delete sports" ON public.sports;
DROP POLICY IF EXISTS "Admins can insert sports" ON public.sports;
DROP POLICY IF EXISTS "Admins can update sports" ON public.sports;

-- Create new admin-only policies for sports with proper role checks
CREATE POLICY "Admins can delete sports" 
ON public.sports 
FOR DELETE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert sports" 
ON public.sports 
FOR INSERT 
TO authenticated
WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update sports" 
ON public.sports 
FOR UPDATE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

-- Drop existing permissive policies for banners
DROP POLICY IF EXISTS "Authenticated users can delete banners" ON public.banners;
DROP POLICY IF EXISTS "Authenticated users can insert banners" ON public.banners;
DROP POLICY IF EXISTS "Authenticated users can update banners" ON public.banners;

-- Create new admin-only policies for banners
CREATE POLICY "Admins can delete banners" 
ON public.banners 
FOR DELETE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert banners" 
ON public.banners 
FOR INSERT 
TO authenticated
WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update banners" 
ON public.banners 
FOR UPDATE 
TO authenticated
USING (has_role(auth.uid(), 'admin'));

-- Fix INPUT_VALIDATION: Add URL protocol constraint for streaming servers
ALTER TABLE public.streaming_servers 
ADD CONSTRAINT valid_url_protocol 
CHECK (server_url LIKE 'https://%' OR server_url LIKE 'http://%');

-- ============================================
-- Source: 20251224103204_2538a0cb-1d7e-4531-9cf9-44fed2046af6.sql
-- ============================================

-- Add ad settings and additional SEO fields to site_settings
ALTER TABLE public.site_settings
ADD COLUMN IF NOT EXISTS header_ad_code text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS sidebar_ad_code text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS footer_ad_code text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS in_article_ad_code text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS popup_ad_code text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS ads_enabled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS google_adsense_id text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS canonical_url text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS robots_txt text DEFAULT 'User-agent: *\nAllow: /',
ADD COLUMN IF NOT EXISTS schema_org_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS twitter_handle text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS facebook_app_id text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS telegram_link text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS social_links jsonb DEFAULT '{}';

-- Add SEO keywords field to matches table for per-match keywords
ALTER TABLE public.matches
ADD COLUMN IF NOT EXISTS seo_keywords text DEFAULT NULL;

-- ============================================
-- Source: 20251224105455_872bb550-0bfd-40cc-82bb-09c740c7d374.sql
-- ============================================

-- Add match_minute column for live score tracking
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS match_minute integer DEFAULT NULL;

-- Add comment
COMMENT ON COLUMN public.matches.match_minute IS 'Current match minute for live matches (e.g., 45 for halftime in football)';

-- ============================================
-- Source: 20251224113523_9770b750-431c-4641-9ab6-e36d3dbcf79e.sql
-- ============================================

-- Add streaming header parameters to streaming_servers table
ALTER TABLE public.streaming_servers
ADD COLUMN referer_value TEXT,
ADD COLUMN origin_value TEXT,
ADD COLUMN cookie_value TEXT,
ADD COLUMN user_agent TEXT;

-- ============================================
-- Source: 20251224114028_dc94a88c-53f4-434c-92f9-12bb1da95bf8.sql
-- ============================================

-- Add DRM fields to streaming_servers table
ALTER TABLE public.streaming_servers
ADD COLUMN drm_license_url TEXT,
ADD COLUMN drm_scheme TEXT DEFAULT NULL;

-- ============================================
-- Source: 20251224114857_652d8987-f913-4cf6-8aff-11cbe4d1540a.sql
-- ============================================

-- Add player_type column to streaming_servers table for M3U8 player selection
ALTER TABLE public.streaming_servers
ADD COLUMN player_type text DEFAULT 'hls' CHECK (player_type IN ('hls', 'clappr'));

COMMENT ON COLUMN public.streaming_servers.player_type IS 'Player type for M3U8 streams: hls (default) or clappr';

-- ============================================
-- Source: 20251224190352_f97bbb43-6dd4-4ce8-816c-75f4ea76352c.sql
-- ============================================

-- Add cricket-specific fields to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS match_format text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS test_day integer DEFAULT NULL,
ADD COLUMN IF NOT EXISTS is_stumps boolean DEFAULT false;

-- Add comments for clarity
COMMENT ON COLUMN public.matches.match_format IS 'Cricket format: Test, ODI, T20, T10, The Hundred';
COMMENT ON COLUMN public.matches.test_day IS 'Current day for Test matches (1-5)';
COMMENT ON COLUMN public.matches.is_stumps IS 'Whether stumps has been called for Test match day';

-- ============================================
-- Source: 20251224190844_71a7d0c2-8e7d-4556-bf46-dc7a8326ec24.sql
-- ============================================

-- Create innings table for cricket match innings tracking
CREATE TABLE public.match_innings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  innings_number INTEGER NOT NULL CHECK (innings_number >= 1 AND innings_number <= 4),
  batting_team_id UUID NOT NULL REFERENCES public.teams(id),
  runs INTEGER DEFAULT 0,
  wickets INTEGER DEFAULT 0 CHECK (wickets >= 0 AND wickets <= 10),
  overs DECIMAL(4,1) DEFAULT 0,
  declared BOOLEAN DEFAULT false,
  is_current BOOLEAN DEFAULT false,
  extras INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(match_id, innings_number)
);

-- Enable Row Level Security
ALTER TABLE public.match_innings ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Innings are viewable by everyone" 
ON public.match_innings 
FOR SELECT 
USING (true);

-- Create policies for admin management
CREATE POLICY "Admins can insert innings" 
ON public.match_innings 
FOR INSERT 
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update innings" 
ON public.match_innings 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete innings" 
ON public.match_innings 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_match_innings_updated_at
BEFORE UPDATE ON public.match_innings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create index for faster queries
CREATE INDEX idx_match_innings_match_id ON public.match_innings(match_id);
CREATE INDEX idx_match_innings_batting_team ON public.match_innings(batting_team_id);

-- ============================================
-- Source: 20251224191505_3bdd407c-edee-45d7-b77f-5e4d22c457e5.sql
-- ============================================

-- Add timing fields for automated STUMPS management
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS stumps_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS day_start_time TIME DEFAULT NULL,
ADD COLUMN IF NOT EXISTS next_day_start TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Add comments for clarity
COMMENT ON COLUMN public.matches.stumps_time IS 'Timestamp when stumps was called for current day';
COMMENT ON COLUMN public.matches.day_start_time IS 'Default daily start time for Test matches (e.g., 10:00 AM local)';
COMMENT ON COLUMN public.matches.next_day_start IS 'Next scheduled start time for play to resume';

-- Enable pg_cron and pg_net extensions for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ============================================
-- Source: 20251224202337_eb1eb6c2-1249-4049-9b12-83d047da8c88.sql
-- ============================================

-- Create table for match playing XI (admin-managed)
CREATE TABLE public.match_playing_xi (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  player_name TEXT NOT NULL,
  player_role TEXT, -- e.g., 'Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'
  is_captain BOOLEAN DEFAULT false,
  is_vice_captain BOOLEAN DEFAULT false,
  is_wicket_keeper BOOLEAN DEFAULT false,
  batting_order INTEGER,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.match_playing_xi ENABLE ROW LEVEL SECURITY;

-- Create policies for playing XI
CREATE POLICY "Playing XI is viewable by everyone" 
ON public.match_playing_xi 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert playing XI" 
ON public.match_playing_xi 
FOR INSERT 
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update playing XI" 
ON public.match_playing_xi 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete playing XI" 
ON public.match_playing_xi 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_match_playing_xi_updated_at
BEFORE UPDATE ON public.match_playing_xi
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create table for tournament points table (admin-managed with full cricket stats)
CREATE TABLE public.tournament_points_table (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  position INTEGER DEFAULT 0,
  played INTEGER DEFAULT 0,
  won INTEGER DEFAULT 0,
  lost INTEGER DEFAULT 0,
  tied INTEGER DEFAULT 0,
  no_result INTEGER DEFAULT 0,
  net_run_rate DECIMAL(6,3) DEFAULT 0.000,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(tournament_id, team_id)
);

-- Enable RLS
ALTER TABLE public.tournament_points_table ENABLE ROW LEVEL SECURITY;

-- Create policies for points table
CREATE POLICY "Points table is viewable by everyone" 
ON public.tournament_points_table 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert points table" 
ON public.tournament_points_table 
FOR INSERT 
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update points table" 
ON public.tournament_points_table 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete points table" 
ON public.tournament_points_table 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_tournament_points_table_updated_at
BEFORE UPDATE ON public.tournament_points_table
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add slug column to tournaments for URL routing
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS slug TEXT UNIQUE;

-- Add is_active column to tournaments to track live/active tournaments
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- ============================================
-- Source: 20251225142011_620290f6-9737-4da6-9a3f-f6c57f81c632.sql
-- ============================================

-- Create a function to update points table when a match is marked completed
CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_score_a TEXT;
  v_score_b TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN;
  v_is_no_result BOOLEAN;
BEGIN
  -- Only process if status changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Get match details
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_score_a := COALESCE(NEW.score_a, '');
    v_score_b := COALESCE(NEW.score_b, '');
    
    -- Only update if match has a tournament
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Determine match result based on score patterns
    -- Check for no result
    v_is_no_result := (
      LOWER(v_score_a) LIKE '%no result%' OR 
      LOWER(v_score_b) LIKE '%no result%' OR
      LOWER(v_score_a) LIKE '%nr%' OR 
      LOWER(v_score_b) LIKE '%nr%' OR
      LOWER(v_score_a) LIKE '%abandoned%' OR 
      LOWER(v_score_b) LIKE '%abandoned%'
    );
    
    -- Check for tie
    v_is_tied := (
      LOWER(v_score_a) LIKE '%tied%' OR 
      LOWER(v_score_b) LIKE '%tied%' OR
      LOWER(v_score_a) LIKE '%draw%' OR 
      LOWER(v_score_b) LIKE '%draw%'
    );
    
    -- Determine winner based on score text (e.g., "Won by X runs", "Won", etc.)
    IF NOT v_is_no_result AND NOT v_is_tied THEN
      IF LOWER(v_score_a) LIKE '%won%' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
      ELSIF LOWER(v_score_b) LIKE '%won%' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
      END IF;
    END IF;
    
    -- Update or insert team A points
    INSERT INTO tournament_points_table (tournament_id, team_id, played, won, lost, tied, no_result, points, position)
    VALUES (
      v_tournament_id, 
      v_team_a_id, 
      1,
      CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE 
        WHEN v_winner_id = v_team_a_id THEN 2
        WHEN v_is_tied THEN 1
        WHEN v_is_no_result THEN 1
        ELSE 0
      END,
      0
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE 
        WHEN v_winner_id = v_team_a_id THEN 2
        WHEN v_is_tied THEN 1
        WHEN v_is_no_result THEN 1
        ELSE 0
      END,
      updated_at = now();
    
    -- Update or insert team B points
    INSERT INTO tournament_points_table (tournament_id, team_id, played, won, lost, tied, no_result, points, position)
    VALUES (
      v_tournament_id, 
      v_team_b_id, 
      1,
      CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE 
        WHEN v_winner_id = v_team_b_id THEN 2
        WHEN v_is_tied THEN 1
        WHEN v_is_no_result THEN 1
        ELSE 0
      END,
      0
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE 
        WHEN v_winner_id = v_team_b_id THEN 2
        WHEN v_is_tied THEN 1
        WHEN v_is_no_result THEN 1
        ELSE 0
      END,
      updated_at = now();
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Add unique constraint for upsert to work
ALTER TABLE tournament_points_table 
ADD CONSTRAINT tournament_points_table_tournament_team_unique 
UNIQUE (tournament_id, team_id);

-- Create trigger for automatic points update
CREATE TRIGGER update_points_on_match_complete_trigger
  AFTER UPDATE OF status ON matches
  FOR EACH ROW
  EXECUTE FUNCTION update_points_on_match_complete();

-- ============================================
-- Source: 20251225143119_1569f0ef-91e2-4d8c-b309-0458de40e81d.sql
-- ============================================

-- Add match_result field to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS match_result text NULL;

-- Add head_to_head tracking columns to tournament_points_table
ALTER TABLE public.tournament_points_table
ADD COLUMN IF NOT EXISTS runs_scored integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS overs_faced numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS runs_conceded integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS overs_bowled numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS head_to_head jsonb DEFAULT '{}'::jsonb;

-- Drop existing trigger with correct name and function with CASCADE
DROP TRIGGER IF EXISTS update_points_on_match_complete_trigger ON public.matches;
DROP TRIGGER IF EXISTS trigger_update_points_on_match_complete ON public.matches;
DROP FUNCTION IF EXISTS public.update_points_on_match_complete() CASCADE;

-- Create improved function to update points table on match completion
CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
BEGIN
  -- Only process if status changed to 'completed' and match_result is set
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    -- Only update if match has a tournament
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Determine match outcome from match_result field
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
      WHEN 'tied' THEN
        v_is_tied := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
      ELSE
        -- No result set, skip processing
        RETURN NEW;
    END CASE;
    
    -- Calculate runs and overs from innings data for NRR
    FOR v_innings_record IN 
      SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
      FROM match_innings 
      WHERE match_id = NEW.id
    LOOP
      IF v_innings_record.batting_team_id = v_team_a_id THEN
        v_team_a_runs := v_team_a_runs + v_innings_record.runs;
        v_team_a_overs := v_team_a_overs + v_innings_record.overs;
      ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
        v_team_b_runs := v_team_b_runs + v_innings_record.runs;
        v_team_b_overs := v_team_b_overs + v_innings_record.overs;
      END IF;
    END LOOP;
    
    -- Update or insert team A points
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, 
      v_team_a_id, 
      1,
      CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE 
        WHEN v_winner_id = v_team_a_id THEN 2
        WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1
        ELSE 0
      END,
      0,
      v_team_a_runs,
      v_team_a_overs,
      v_team_b_runs,
      v_team_b_overs,
      CASE 
        WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE 
        WHEN v_winner_id = v_team_a_id THEN 2
        WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1
        ELSE 0
      END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_a_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_a_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_b_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_b_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_a_id THEN 
          jsonb_set(
            COALESCE(tournament_points_table.head_to_head, '{}'::jsonb),
            ARRAY[v_team_b_id::text],
            jsonb_build_object(
              'won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0) + 1,
              'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0)
            )
          )
        WHEN v_loser_id = v_team_a_id THEN 
          jsonb_set(
            COALESCE(tournament_points_table.head_to_head, '{}'::jsonb),
            ARRAY[v_team_b_id::text],
            jsonb_build_object(
              'won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0),
              'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1
            )
          )
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Update or insert team B points
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, 
      v_team_b_id, 
      1,
      CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE 
        WHEN v_winner_id = v_team_b_id THEN 2
        WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1
        ELSE 0
      END,
      0,
      v_team_b_runs,
      v_team_b_overs,
      v_team_a_runs,
      v_team_a_overs,
      CASE 
        WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE 
        WHEN v_winner_id = v_team_b_id THEN 2
        WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1
        ELSE 0
      END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_b_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_b_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_a_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_a_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_b_id THEN 
          jsonb_set(
            COALESCE(tournament_points_table.head_to_head, '{}'::jsonb),
            ARRAY[v_team_a_id::text],
            jsonb_build_object(
              'won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0) + 1,
              'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0)
            )
          )
        WHEN v_loser_id = v_team_b_id THEN 
          jsonb_set(
            COALESCE(tournament_points_table.head_to_head, '{}'::jsonb),
            ARRAY[v_team_a_id::text],
            jsonb_build_object(
              'won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0),
              'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1
            )
          )
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Update NRR for both teams
    UPDATE tournament_points_table SET
      net_run_rate = CASE 
        WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
          ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
        ELSE 0
      END
    WHERE tournament_id = v_tournament_id 
      AND team_id IN (v_team_a_id, v_team_b_id);
    
    -- Auto-update positions for all teams in the tournament
    WITH ranked_teams AS (
      SELECT 
        id,
        ROW_NUMBER() OVER (
          ORDER BY 
            COALESCE(points, 0) DESC,
            COALESCE(net_run_rate, 0) DESC,
            COALESCE(won, 0) DESC
        ) as new_position
      FROM tournament_points_table
      WHERE tournament_id = v_tournament_id
    )
    UPDATE tournament_points_table t
    SET position = r.new_position
    FROM ranked_teams r
    WHERE t.id = r.id;
    
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Create the trigger
CREATE TRIGGER trigger_update_points_on_match_complete
  AFTER UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_points_on_match_complete();

-- Create function to recalculate all positions for a tournament
CREATE OR REPLACE FUNCTION public.recalculate_tournament_positions(p_tournament_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE tournament_points_table SET
    net_run_rate = CASE 
      WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
        ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
      ELSE 0
    END
  WHERE tournament_id = p_tournament_id;
  
  WITH ranked_teams AS (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        ORDER BY 
          COALESCE(points, 0) DESC,
          COALESCE(net_run_rate, 0) DESC,
          COALESCE(won, 0) DESC
      ) as new_position
    FROM tournament_points_table
    WHERE tournament_id = p_tournament_id
  )
  UPDATE tournament_points_table t
  SET position = r.new_position
  FROM ranked_teams r
  WHERE t.id = r.id;
END;
$function$;

-- ============================================
-- Source: 20251225150144_e22a14af-4e8d-4105-a1ec-715348810f93.sql
-- ============================================

-- Add cricket API settings to site_settings
ALTER TABLE site_settings 
ADD COLUMN IF NOT EXISTS cricket_api_key TEXT,
ADD COLUMN IF NOT EXISTS cricket_api_enabled BOOLEAN DEFAULT true;

-- Add per-match API score toggle
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS api_score_enabled BOOLEAN DEFAULT true;

-- ============================================
-- Source: 20251225154608_10b37d25-d597-465f-9aae-7a52b71e84cf.sql
-- ============================================

-- Add cricbuzz_match_id column to matches table for alternative score source
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS cricbuzz_match_id text;

-- Change default of cricket_api_enabled to false (off by default)
ALTER TABLE public.site_settings ALTER COLUMN cricket_api_enabled SET DEFAULT false;

-- Also set api_score_enabled on matches to default false
ALTER TABLE public.matches ALTER COLUMN api_score_enabled SET DEFAULT false;

-- Add comment for clarity
COMMENT ON COLUMN public.matches.cricbuzz_match_id IS 'Cricbuzz match ID for fetching live scores from Cricbuzz as alternative to CricAPI';

-- ============================================
-- Source: 20251225172627_f9ed0eb3-ebb3-4e02-80dd-90910b252973.sql
-- ============================================

-- Enable pg_net extension for HTTP calls from triggers
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create function to call fetch-match-result edge function when match becomes completed
CREATE OR REPLACE FUNCTION public.auto_fetch_match_result()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_response_id bigint;
BEGIN
  -- Only trigger when status changes to 'completed' and api_score_enabled is true and has cricbuzz_match_id
  IF NEW.status = 'completed' 
     AND (OLD.status IS NULL OR OLD.status != 'completed')
     AND NEW.api_score_enabled = true 
     AND NEW.cricbuzz_match_id IS NOT NULL THEN
    
    -- Call the edge function via HTTP
    SELECT extensions.http_post(
      url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/fetch-match-result',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcXRlZm9ydW1qZHVnaWZ4cnlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NDY5NjQsImV4cCI6MjA4MjEyMjk2NH0.TzRAPhPWC6WN_IR24qEWA8TznqlrqPirJBdDmWyT9n8'
      ),
      body := jsonb_build_object(
        'matchId', NEW.id,
        'cricbuzzMatchId', NEW.cricbuzz_match_id
      )
    ) INTO v_response_id;
    
    RAISE LOG 'Auto-fetch match result triggered for match %, response_id: %', NEW.id, v_response_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-fetch result when match status changes to completed
DROP TRIGGER IF EXISTS trigger_auto_fetch_match_result ON public.matches;
CREATE TRIGGER trigger_auto_fetch_match_result
  AFTER UPDATE OF status ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_fetch_match_result();

-- ============================================
-- Source: 20251225175957_d9837996-a36e-492d-87de-d71b7892af91.sql
-- ============================================

-- Drop the trigger first, then the function
DROP TRIGGER IF EXISTS trigger_auto_fetch_match_result ON matches;
DROP FUNCTION IF EXISTS public.auto_fetch_match_result() CASCADE;

-- ============================================
-- Source: 20251225181339_c6438c12-2608-4fc2-81cf-de054609c12b.sql
-- ============================================

-- Add SEO fields to tournaments table
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS seo_title TEXT,
ADD COLUMN IF NOT EXISTS seo_description TEXT,
ADD COLUMN IF NOT EXISTS seo_keywords TEXT;

-- ============================================
-- Source: 20251225185848_625ffd1c-9fab-4ad6-9004-52c96b6587b3.sql
-- ============================================

-- Create a public view that excludes sensitive fields
CREATE OR REPLACE VIEW public.site_settings_public AS
SELECT 
  id, site_name, site_title, site_description, site_keywords,
  logo_url, favicon_url, og_image_url, footer_text,
  google_analytics_id, ads_enabled, schema_org_enabled,
  social_links, telegram_link, canonical_url, robots_txt,
  twitter_handle, facebook_app_id,
  header_ad_code, sidebar_ad_code, footer_ad_code,
  in_article_ad_code, popup_ad_code, google_adsense_id,
  cricket_api_enabled,
  created_at, updated_at
FROM public.site_settings;

-- Grant SELECT on public view to anon and authenticated
GRANT SELECT ON public.site_settings_public TO anon, authenticated;

-- Drop the existing public SELECT policy
DROP POLICY IF EXISTS "Site settings are viewable by everyone" ON public.site_settings;

-- Create new policy that only allows admins to SELECT full site settings
CREATE POLICY "Admins can read all site settings"
ON public.site_settings FOR SELECT
USING (has_role(auth.uid(), 'admin'));

-- ============================================
-- Source: 20251225185931_0ab6b2af-363d-4c3c-b74f-e27cfeffc655.sql
-- ============================================

-- Fix security definer view by recreating with security_invoker
DROP VIEW IF EXISTS public.site_settings_public;

CREATE VIEW public.site_settings_public 
WITH (security_invoker = true) AS
SELECT 
  id, site_name, site_title, site_description, site_keywords,
  logo_url, favicon_url, og_image_url, footer_text,
  google_analytics_id, ads_enabled, schema_org_enabled,
  social_links, telegram_link, canonical_url, robots_txt,
  twitter_handle, facebook_app_id,
  header_ad_code, sidebar_ad_code, footer_ad_code,
  in_article_ad_code, popup_ad_code, google_adsense_id,
  cricket_api_enabled,
  created_at, updated_at
FROM public.site_settings;

-- Grant SELECT on public view to anon and authenticated
GRANT SELECT ON public.site_settings_public TO anon, authenticated;

-- ============================================
-- Source: 20251226072948_84e66d17-b2ac-4ebc-8582-4c6b74f57502.sql
-- ============================================

-- Add ad_block_enabled column to streaming_servers table
ALTER TABLE public.streaming_servers 
ADD COLUMN ad_block_enabled boolean DEFAULT false;

-- ============================================
-- Source: 20251226103609_f54ef500-4a98-4c99-8dd0-ab35e9dc64d4.sql
-- ============================================

-- Add SMTP configuration columns to site_settings
ALTER TABLE public.site_settings
ADD COLUMN IF NOT EXISTS smtp_enabled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS smtp_host text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS smtp_port integer DEFAULT 587,
ADD COLUMN IF NOT EXISTS smtp_user text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS smtp_password text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS smtp_from_email text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS smtp_from_name text DEFAULT NULL;

-- ============================================
-- Source: 20251226104433_b16541c3-2cfa-48f0-a7e5-0faa2d40bfa4.sql
-- ============================================

-- Create table for storing OTP codes
CREATE TABLE public.admin_otp_codes (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL,
  otp_code text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  is_used boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.admin_otp_codes ENABLE ROW LEVEL SECURITY;

-- Only service role can manage OTP codes (edge functions use service role)
CREATE POLICY "Service role can manage OTP codes"
ON public.admin_otp_codes
FOR ALL
USING (true)
WITH CHECK (true);

-- Create index for faster lookups
CREATE INDEX idx_admin_otp_codes_user_id ON public.admin_otp_codes(user_id);
CREATE INDEX idx_admin_otp_codes_expires_at ON public.admin_otp_codes(expires_at);

-- ============================================
-- Source: 20251226105752_8ebfc5b8-0c0c-464c-b281-eed73d46bce7.sql
-- ============================================

-- Add ads.txt content column to site_settings
ALTER TABLE public.site_settings
ADD COLUMN IF NOT EXISTS ads_txt_content text DEFAULT NULL;

-- ============================================
-- Source: 20251226105851_7212c4a0-a926-42e6-9855-faffc4a72a79.sql
-- ============================================

-- Drop and recreate the public view to include ads_txt_content
DROP VIEW IF EXISTS public.site_settings_public;

CREATE VIEW public.site_settings_public AS
SELECT 
  id,
  site_name,
  site_title,
  site_description,
  site_keywords,
  logo_url,
  favicon_url,
  og_image_url,
  footer_text,
  google_analytics_id,
  created_at,
  updated_at,
  header_ad_code,
  sidebar_ad_code,
  footer_ad_code,
  in_article_ad_code,
  popup_ad_code,
  ads_enabled,
  google_adsense_id,
  canonical_url,
  robots_txt,
  schema_org_enabled,
  twitter_handle,
  facebook_app_id,
  telegram_link,
  social_links,
  cricket_api_enabled,
  ads_txt_content
FROM site_settings;

-- ============================================
-- Source: 20251226105916_a21d8426-23e6-40e8-838b-f69ee9996a98.sql
-- ============================================

-- Fix the security definer view by setting security_invoker
ALTER VIEW public.site_settings_public SET (security_invoker = on);

-- ============================================
-- Source: 20251226110729_bd917cde-3edd-43ea-b586-491f5364c38b.sql
-- ============================================

-- Drop and recreate the view with security_invoker = off so anonymous users can read it
DROP VIEW IF EXISTS public.site_settings_public;

CREATE OR REPLACE VIEW public.site_settings_public WITH (security_invoker = off) AS
SELECT 
  id,
  site_name,
  site_title,
  site_description,
  site_keywords,
  logo_url,
  favicon_url,
  og_image_url,
  footer_text,
  google_analytics_id,
  created_at,
  updated_at,
  header_ad_code,
  sidebar_ad_code,
  footer_ad_code,
  in_article_ad_code,
  popup_ad_code,
  ads_enabled,
  google_adsense_id,
  canonical_url,
  robots_txt,
  schema_org_enabled,
  twitter_handle,
  facebook_app_id,
  telegram_link,
  social_links,
  cricket_api_enabled,
  ads_txt_content
FROM public.site_settings;

-- Grant select permission to anonymous and authenticated users
GRANT SELECT ON public.site_settings_public TO anon;
GRANT SELECT ON public.site_settings_public TO authenticated;

-- ============================================
-- Source: 20251226111448_eac854f3-bb86-4f36-9d9d-25f8c70ebaec.sql
-- ============================================

-- Replace security-definer view with a real public settings table synced from site_settings
DROP VIEW IF EXISTS public.site_settings_public;

CREATE TABLE IF NOT EXISTS public.site_settings_public (
  id uuid PRIMARY KEY,
  site_name text,
  site_title text,
  site_description text,
  site_keywords text,
  logo_url text,
  favicon_url text,
  og_image_url text,
  footer_text text,
  google_analytics_id text,
  created_at timestamptz,
  updated_at timestamptz,
  header_ad_code text,
  sidebar_ad_code text,
  footer_ad_code text,
  in_article_ad_code text,
  popup_ad_code text,
  ads_enabled boolean,
  google_adsense_id text,
  canonical_url text,
  robots_txt text,
  schema_org_enabled boolean,
  twitter_handle text,
  facebook_app_id text,
  telegram_link text,
  social_links jsonb,
  cricket_api_enabled boolean,
  ads_txt_content text
);

-- Keep it publicly readable (safe subset only)
ALTER TABLE public.site_settings_public ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public site settings are viewable by everyone" ON public.site_settings_public;
CREATE POLICY "Public site settings are viewable by everyone"
ON public.site_settings_public
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Admins can manage public site settings" ON public.site_settings_public;
CREATE POLICY "Admins can manage public site settings"
ON public.site_settings_public
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Permissions (RLS still applies)
REVOKE ALL ON public.site_settings_public FROM anon, authenticated;
GRANT SELECT ON public.site_settings_public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_settings_public TO authenticated;

-- Initial backfill (copy all existing rows)
INSERT INTO public.site_settings_public (
  id,
  site_name,
  site_title,
  site_description,
  site_keywords,
  logo_url,
  favicon_url,
  og_image_url,
  footer_text,
  google_analytics_id,
  created_at,
  updated_at,
  header_ad_code,
  sidebar_ad_code,
  footer_ad_code,
  in_article_ad_code,
  popup_ad_code,
  ads_enabled,
  google_adsense_id,
  canonical_url,
  robots_txt,
  schema_org_enabled,
  twitter_handle,
  facebook_app_id,
  telegram_link,
  social_links,
  cricket_api_enabled,
  ads_txt_content
)
SELECT
  id,
  site_name,
  site_title,
  site_description,
  site_keywords,
  logo_url,
  favicon_url,
  og_image_url,
  footer_text,
  google_analytics_id,
  created_at,
  updated_at,
  header_ad_code,
  sidebar_ad_code,
  footer_ad_code,
  in_article_ad_code,
  popup_ad_code,
  ads_enabled,
  google_adsense_id,
  canonical_url,
  robots_txt,
  schema_org_enabled,
  twitter_handle,
  facebook_app_id,
  telegram_link,
  social_links,
  cricket_api_enabled,
  ads_txt_content
FROM public.site_settings
ON CONFLICT (id) DO UPDATE SET
  site_name = EXCLUDED.site_name,
  site_title = EXCLUDED.site_title,
  site_description = EXCLUDED.site_description,
  site_keywords = EXCLUDED.site_keywords,
  logo_url = EXCLUDED.logo_url,
  favicon_url = EXCLUDED.favicon_url,
  og_image_url = EXCLUDED.og_image_url,
  footer_text = EXCLUDED.footer_text,
  google_analytics_id = EXCLUDED.google_analytics_id,
  created_at = EXCLUDED.created_at,
  updated_at = EXCLUDED.updated_at,
  header_ad_code = EXCLUDED.header_ad_code,
  sidebar_ad_code = EXCLUDED.sidebar_ad_code,
  footer_ad_code = EXCLUDED.footer_ad_code,
  in_article_ad_code = EXCLUDED.in_article_ad_code,
  popup_ad_code = EXCLUDED.popup_ad_code,
  ads_enabled = EXCLUDED.ads_enabled,
  google_adsense_id = EXCLUDED.google_adsense_id,
  canonical_url = EXCLUDED.canonical_url,
  robots_txt = EXCLUDED.robots_txt,
  schema_org_enabled = EXCLUDED.schema_org_enabled,
  twitter_handle = EXCLUDED.twitter_handle,
  facebook_app_id = EXCLUDED.facebook_app_id,
  telegram_link = EXCLUDED.telegram_link,
  social_links = EXCLUDED.social_links,
  cricket_api_enabled = EXCLUDED.cricket_api_enabled,
  ads_txt_content = EXCLUDED.ads_txt_content;

-- Sync function + trigger
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_site_settings_public_trigger ON public.site_settings;
CREATE TRIGGER sync_site_settings_public_trigger
AFTER INSERT OR UPDATE
ON public.site_settings
FOR EACH ROW
EXECUTE FUNCTION public.sync_site_settings_public_from_site_settings();


-- ============================================
-- Source: 20251226121347_8d2f434a-1b4a-4b39-a119-ed11e22fe639.sql
-- ============================================

-- Add match_end_time column for alternative to match_duration_minutes
ALTER TABLE public.matches 
ADD COLUMN match_end_time timestamp with time zone DEFAULT NULL;

-- ============================================
-- Source: 20251226133500_9ed93908-98d4-47ef-99b7-2f2f43cdbca9.sql
-- ============================================

-- Create dynamic pages table for DMCA, Contact, and other custom pages
CREATE TABLE public.dynamic_pages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT,
  content_type TEXT NOT NULL DEFAULT 'html', -- 'html' or 'text'
  is_active BOOLEAN DEFAULT true,
  show_in_header BOOLEAN DEFAULT false,
  show_in_footer BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  seo_title TEXT,
  seo_description TEXT,
  seo_keywords TEXT,
  og_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.dynamic_pages ENABLE ROW LEVEL SECURITY;

-- Public can view active pages
CREATE POLICY "Active pages are viewable by everyone" 
ON public.dynamic_pages 
FOR SELECT 
USING (is_active = true);

-- Admins can manage all pages
CREATE POLICY "Admins can insert pages" 
ON public.dynamic_pages 
FOR INSERT 
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update pages" 
ON public.dynamic_pages 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete pages" 
ON public.dynamic_pages 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for updated_at
CREATE TRIGGER update_dynamic_pages_updated_at
BEFORE UPDATE ON public.dynamic_pages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add new columns to site_settings for custom header/footer code and ad positions
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS custom_header_code TEXT,
ADD COLUMN IF NOT EXISTS custom_footer_code TEXT,
ADD COLUMN IF NOT EXISTS match_page_ad_positions JSONB DEFAULT '{"before_player": true, "after_player": true, "sidebar": true, "below_info": true}'::jsonb;

-- Add same columns to site_settings_public
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS custom_header_code TEXT,
ADD COLUMN IF NOT EXISTS custom_footer_code TEXT,
ADD COLUMN IF NOT EXISTS match_page_ad_positions JSONB DEFAULT '{"before_player": true, "after_player": true, "sidebar": true, "below_info": true}'::jsonb;

-- Update the sync function to include new columns
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions;

  RETURN NEW;
END;
$function$;

-- Insert default pages (DMCA and Contact Us)
INSERT INTO public.dynamic_pages (slug, title, content, content_type, show_in_header, show_in_footer, display_order, seo_title, seo_description)
VALUES 
  ('dmca', 'DMCA', '<h1>DMCA Policy</h1><p>This is a placeholder for your DMCA policy. Please edit this content from the admin panel.</p>', 'html', true, true, 1, 'DMCA Policy', 'DMCA takedown policy and copyright information'),
  ('contact-us', 'Contact Us', '<h1>Contact Us</h1><p>This is a placeholder for your contact information. Please edit this content from the admin panel.</p>', 'html', true, true, 2, 'Contact Us', 'Get in touch with us')
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- Source: 20251226135802_f6baaa85-127e-4ad7-93e5-cfb7d22f177b.sql
-- ============================================

-- Add show_in_menu column to tournaments table
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS show_in_menu BOOLEAN DEFAULT true;

-- Update existing tournaments to show in menu by default
UPDATE public.tournaments SET show_in_menu = true WHERE show_in_menu IS NULL;

-- ============================================
-- Source: 20251226195842_459d5e2f-11c3-40ae-a0de-058420e33d53.sql
-- ============================================

-- Add key_id and clearkey columns for MPD/DASH ClearKey DRM support
ALTER TABLE public.streaming_servers
ADD COLUMN IF NOT EXISTS clearkey_key_id TEXT,
ADD COLUMN IF NOT EXISTS clearkey_key TEXT;

-- ============================================
-- Source: 20251227064357_ebe4d250-498c-4446-b5aa-85888c1f927a.sql
-- ============================================

-- Create table for saved/template streaming servers
CREATE TABLE public.saved_streaming_servers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  server_name TEXT NOT NULL,
  server_url TEXT NOT NULL,
  server_type TEXT NOT NULL DEFAULT 'iframe',
  referer_value TEXT,
  origin_value TEXT,
  cookie_value TEXT,
  user_agent TEXT,
  drm_license_url TEXT,
  drm_scheme TEXT,
  player_type TEXT DEFAULT 'hls',
  ad_block_enabled BOOLEAN DEFAULT false,
  clearkey_key_id TEXT,
  clearkey_key TEXT,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.saved_streaming_servers ENABLE ROW LEVEL SECURITY;

-- Create policies for admin access
CREATE POLICY "Admins can manage saved streaming servers" 
ON public.saved_streaming_servers 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for updated_at
CREATE TRIGGER update_saved_streaming_servers_updated_at
BEFORE UPDATE ON public.saved_streaming_servers
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create simple index for text search on server_name
CREATE INDEX idx_saved_streaming_servers_name ON public.saved_streaming_servers (server_name);

-- Create index for tags search
CREATE INDEX idx_saved_streaming_servers_tags ON public.saved_streaming_servers USING GIN (tags);

-- ============================================
-- Source: 20251227175516_c3f22872-14d6-4d96-826d-975a68e2346d.sql
-- ============================================

-- Enable realtime for matches table
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;

-- Enable realtime for match_innings table (for innings updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.match_innings;

-- ============================================
-- Source: 20251228072015_260c907e-ef13-4a58-a66a-a33848d17d1e.sql
-- ============================================

CREATE OR REPLACE FUNCTION public.recalculate_tournament_positions(p_tournament_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Only update NRR if we have the overs data to calculate it
  -- Otherwise preserve the existing net_run_rate value
  UPDATE tournament_points_table SET
    net_run_rate = CASE 
      WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
        ROUND(((COALESCE(runs_scored, 0)::numeric / overs_faced) - (COALESCE(runs_conceded, 0)::numeric / overs_bowled))::numeric, 3)
      ELSE 
        -- Preserve existing NRR if overs data is not available
        net_run_rate
    END
  WHERE tournament_id = p_tournament_id;
  
  WITH ranked_teams AS (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        ORDER BY 
          COALESCE(points, 0) DESC,
          COALESCE(net_run_rate, 0) DESC,
          COALESCE(won, 0) DESC
      ) as new_position
    FROM tournament_points_table
    WHERE tournament_id = p_tournament_id
  )
  UPDATE tournament_points_table t
  SET position = r.new_position
  FROM ranked_teams r
  WHERE t.id = r.id;
END;
$function$;

-- ============================================
-- Source: 20251228072604_6b32979b-4641-4760-9c7a-437fd9960dbe.sql
-- ============================================

-- Add ad_block_rules column to site_settings table
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS ad_block_rules JSONB DEFAULT '{"cssSelectors": [".ad", ".ads", ".advert", ".advertisement", ".ad-container", ".ad-wrapper", ".banner-ad", ".top-ad", ".bottom-ad", ".sidebar-ad", ".popup", ".popunder", ".overlay-ad", ".interstitial", ".sticky-ad", ".fixed-ad", ".floating-ad", ".modal-backdrop", ".modal-overlay"], "blockPopups": true, "blockNewTabs": true}'::jsonb;

-- Add ad_block_rules column to site_settings_public table
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS ad_block_rules JSONB DEFAULT '{"cssSelectors": [".ad", ".ads", ".advert", ".advertisement", ".ad-container", ".ad-wrapper", ".banner-ad", ".top-ad", ".bottom-ad", ".sidebar-ad", ".popup", ".popunder", ".overlay-ad", ".interstitial", ".sticky-ad", ".fixed-ad", ".floating-ad", ".modal-backdrop", ".modal-overlay"], "blockPopups": true, "blockNewTabs": true}'::jsonb;

-- ============================================
-- Source: 20251228112137_5c9dd7cb-2acd-4e71-a1c8-117a40135350.sql
-- ============================================

-- Add api-cricket.com settings columns to site_settings table
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS api_cricket_key text DEFAULT NULL,
ADD COLUMN IF NOT EXISTS api_cricket_enabled boolean DEFAULT false;

-- Add to site_settings_public table
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS api_cricket_enabled boolean DEFAULT false;

-- Update the trigger function to sync the new column
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20251228123501_f0a3ee0d-d0d5-46e7-9629-4f65dbfe9733.sql
-- ============================================

-- Add auto-sync columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS auto_sync_enabled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS last_api_sync timestamp with time zone;

-- Add comment for clarity
COMMENT ON COLUMN public.matches.auto_sync_enabled IS 'Whether this match should be auto-synced by admin panel';
COMMENT ON COLUMN public.matches.last_api_sync IS 'Last time this match was synced from the API';

-- ============================================
-- Source: 20251228180926_ae3c4249-e7fe-42cb-8ebf-1a36b503ebb9.sql
-- ============================================

-- Create table to store API cricket scores synced from admin side
CREATE TABLE IF NOT EXISTS public.match_api_scores (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  home_team TEXT,
  away_team TEXT,
  home_score TEXT,
  away_score TEXT,
  home_overs TEXT,
  away_overs TEXT,
  status TEXT,
  status_info TEXT,
  event_live BOOLEAN DEFAULT false,
  venue TEXT,
  toss TEXT,
  batsmen JSONB DEFAULT '[]'::jsonb,
  bowlers JSONB DEFAULT '[]'::jsonb,
  extras JSONB DEFAULT '[]'::jsonb,
  scorecard JSONB DEFAULT '[]'::jsonb,
  api_event_key TEXT,
  last_synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(match_id)
);

-- Enable RLS
ALTER TABLE public.match_api_scores ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Match API scores are viewable by everyone" 
ON public.match_api_scores 
FOR SELECT 
USING (true);

-- Admin write access
CREATE POLICY "Admins can manage match API scores" 
ON public.match_api_scores 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Service role can manage (for edge function)
CREATE POLICY "Service role can manage match API scores" 
ON public.match_api_scores 
FOR ALL 
USING (true)
WITH CHECK (true);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_match_api_scores_match_id ON public.match_api_scores(match_id);

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE public.match_api_scores;

-- Create trigger for updated_at
CREATE TRIGGER update_match_api_scores_updated_at
BEFORE UPDATE ON public.match_api_scores
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- Source: 20251228181820_19067854-0a82-48b1-b3a3-9ca5ee425699.sql
-- ============================================

-- Add sync interval setting to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS api_sync_interval_seconds INTEGER DEFAULT 120;

-- Add to public mirror table
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS api_sync_interval_seconds INTEGER DEFAULT 120;

-- Update the sync trigger to include the new column
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20251230083508_79863a87-a629-4621-9e46-d49155c22f3c.sql
-- ============================================

-- Add is_active column to matches table (default true)
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- ============================================
-- Source: 20251230103614_8ecd9ca5-3dd0-43e3-b89d-abe131214d47.sql
-- ============================================

-- Drop the existing status check constraint and add a new one with more status options
ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_status_check;

-- Add new check constraint with all possible status values
ALTER TABLE public.matches ADD CONSTRAINT matches_status_check 
CHECK (status IN ('upcoming', 'live', 'completed', 'cancelled', 'abandoned', 'postponed', 'delayed', 'interrupted'));

-- ============================================
-- Source: 20260103040448_24a85df9-be93-4862-bfc8-0cc40e0e5f4c.sql
-- ============================================

-- Create table to track sitemap ping history
CREATE TABLE public.sitemap_ping_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  ping_type TEXT NOT NULL DEFAULT 'manual', -- 'manual', 'auto_match', 'auto_tournament', 'auto_page'
  triggered_by TEXT, -- match_id, tournament_id, page_id, or 'manual'
  sitemap_url TEXT NOT NULL,
  results JSONB DEFAULT '[]'::jsonb,
  success_count INTEGER DEFAULT 0,
  total_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.sitemap_ping_history ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read ping history
CREATE POLICY "Ping history is viewable by everyone"
ON public.sitemap_ping_history
FOR SELECT
USING (true);

-- Admins can manage ping history
CREATE POLICY "Admins can manage ping history"
ON public.sitemap_ping_history
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Service role can manage ping history (for edge functions)
CREATE POLICY "Service role can manage ping history"
ON public.sitemap_ping_history
FOR ALL
USING (true)
WITH CHECK (true);

-- Create index for faster lookups
CREATE INDEX idx_sitemap_ping_history_created_at ON public.sitemap_ping_history(created_at DESC);
CREATE INDEX idx_sitemap_ping_history_ping_type ON public.sitemap_ping_history(ping_type);

-- ============================================
-- Source: 20260106075314_5b92b203-98b0-40bc-90cb-fe7a6f5d3e05.sql
-- ============================================


-- Drop the admin-only SELECT policy
DROP POLICY IF EXISTS "Only admins can view streaming servers" ON public.streaming_servers;

-- Create a new policy that allows everyone to view active streaming servers (for match pages)
CREATE POLICY "Anyone can view active streaming servers" 
ON public.streaming_servers 
FOR SELECT 
USING (is_active = true);


-- ============================================
-- Source: 20260106110519_31047d34-e614-4591-a8ff-8efbb8df9eb2.sql
-- ============================================

-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant usage on cron schema to postgres
GRANT USAGE ON SCHEMA cron TO postgres;

-- Create a function to call edge functions
CREATE OR REPLACE FUNCTION public.call_update_match_status()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
BEGIN
  -- Call the edge function via HTTP (internal call without auth)
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/update-match-status',
    ARRAY[extensions.http_header('Content-Type', 'application/json')],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'update-match-status result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'update-match-status error: %', SQLERRM;
END;
$$;

-- Create a function to call sync-api-scores
CREATE OR REPLACE FUNCTION public.call_sync_api_scores()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
BEGIN
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-api-scores',
    ARRAY[extensions.http_header('Content-Type', 'application/json')],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'sync-api-scores result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'sync-api-scores error: %', SQLERRM;
END;
$$;

-- Schedule update-match-status to run every minute
SELECT cron.schedule(
  'update-match-status-every-minute',
  '* * * * *',
  $$SELECT public.call_update_match_status()$$
);

-- Schedule sync-api-scores to run every minute
SELECT cron.schedule(
  'sync-api-scores-every-minute',
  '* * * * *',
  $$SELECT public.call_sync_api_scores()$$
);

-- ============================================
-- Source: 20260106110549_f3cfe9e2-4f61-420d-940e-9913c4c37525.sql
-- ============================================

-- Remove duplicate/old cron jobs
SELECT cron.unschedule('update-match-status-job');
SELECT cron.unschedule('auto-sync-live-scores');

-- ============================================
-- Source: 20260106110729_28c77b1e-99d4-4a51-bc03-4205444bb6c8.sql
-- ============================================

-- Update the cron functions to include service role authorization
CREATE OR REPLACE FUNCTION public.call_update_match_status()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
  _service_role_key text;
BEGIN
  -- Get the service role key from vault (if available) or use a direct approach
  _service_role_key := current_setting('app.settings.service_role_key', true);
  
  -- Call the edge function via HTTP with service role authorization
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/update-match-status',
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || _service_role_key)
    ],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'update-match-status result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'update-match-status error: %', SQLERRM;
END;
$$;

-- Update sync-api-scores function
CREATE OR REPLACE FUNCTION public.call_sync_api_scores()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
  _service_role_key text;
BEGIN
  _service_role_key := current_setting('app.settings.service_role_key', true);
  
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-api-scores',
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || _service_role_key)
    ],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'sync-api-scores result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'sync-api-scores error: %', SQLERRM;
END;
$$;

-- ============================================
-- Source: 20260106110834_f1823608-219c-4d88-8a5e-c5eaa61b9aa2.sql
-- ============================================

-- Simplify cron functions - just make HTTP call without auth (anon key will be used by default)
CREATE OR REPLACE FUNCTION public.call_update_match_status()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
BEGIN
  -- Call the edge function via HTTP (will use anon key automatically)
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/update-match-status',
    ARRAY[extensions.http_header('Content-Type', 'application/json')],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'update-match-status result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'update-match-status error: %', SQLERRM;
END;
$$;

CREATE OR REPLACE FUNCTION public.call_sync_api_scores()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _result text;
BEGIN
  SELECT content::text INTO _result
  FROM extensions.http((
    'POST',
    'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-api-scores',
    ARRAY[extensions.http_header('Content-Type', 'application/json')],
    'application/json',
    '{}'
  )::extensions.http_request);
  
  RAISE LOG 'sync-api-scores result: %', _result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'sync-api-scores error: %', SQLERRM;
END;
$$;

-- ============================================
-- Source: 20260106111108_5849fe43-fb10-4ce5-8119-f969c8d8fb81.sql
-- ============================================

-- Enable pg_net extension and recreate functions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Recreate cron functions using pg_net
CREATE OR REPLACE FUNCTION public.call_update_match_status()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/update-match-status',
    body := '{}'::jsonb
  );
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'update-match-status error: %', SQLERRM;
END;
$$;

CREATE OR REPLACE FUNCTION public.call_sync_api_scores()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-api-scores',
    body := '{}'::jsonb
  );
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'sync-api-scores error: %', SQLERRM;
END;
$$;

-- ============================================
-- Source: 20260108153136_3c250a50-73c7-4318-81ec-e31138115969.sql
-- ============================================

-- Add RapidAPI key column to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS rapidapi_key text,
ADD COLUMN IF NOT EXISTS rapidapi_enabled boolean DEFAULT false;

-- Add to public view as well
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS rapidapi_enabled boolean DEFAULT false;

-- ============================================
-- Source: 20260108155550_378ff37c-d213-45e5-a812-80fb78ddb2c9.sql
-- ============================================

-- Add series_id column to tournaments table for storing Cricbuzz series ID
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS series_id text;

-- Comment for the column
COMMENT ON COLUMN public.tournaments.series_id IS 'Cricbuzz series ID for API sync';

-- ============================================
-- Source: 20260114192519_8634ffb2-02fc-421c-bf11-1971dffe4853.sql
-- ============================================

-- Add result_margin column to store winning margin text like "by 7 wickets"
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS result_margin TEXT;

-- ============================================
-- Source: 20260114192913_283af8ed-9381-4820-aeef-5a18fb6fe497.sql
-- ============================================

-- Add show_in_homepage column to tournaments table for hiding from homepage list
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS show_in_homepage BOOLEAN DEFAULT true;

-- ============================================
-- Source: 20260115030510_aefc1b27-8d17-42c8-b4bb-4444aa3ebf69.sql
-- ============================================

-- Add new columns for tournament details and SEO
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS total_matches INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT NULL;

-- ============================================
-- Source: 20260115033034_cf29843d-e4cf-40b3-a425-62874caaf8c0.sql
-- ============================================

-- Add is_completed column to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN is_completed boolean DEFAULT false;

-- ============================================
-- Source: 20260115034015_728a4aae-4594-4438-8895-7e76ef3c4007.sql
-- ============================================

-- Add total_teams and total_venues columns to tournaments table
ALTER TABLE public.tournaments
ADD COLUMN total_teams INTEGER DEFAULT NULL,
ADD COLUMN total_venues INTEGER DEFAULT NULL;

-- ============================================
-- Source: 20260116041816_b338de0c-09a1-434e-88d4-5fd1e821523e.sql
-- ============================================

-- Create sponsor_notices table for stream page notices
CREATE TABLE public.sponsor_notices (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  position TEXT NOT NULL DEFAULT 'before_stream' CHECK (position IN ('before_stream', 'before_servers', 'before_scoreboard')),
  display_type TEXT NOT NULL DEFAULT 'static' CHECK (display_type IN ('static', 'marquee')),
  text_color TEXT DEFAULT '#ffffff',
  background_color TEXT DEFAULT '#1a1a2e',
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
  is_global BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.sponsor_notices ENABLE ROW LEVEL SECURITY;

-- Public read policy
CREATE POLICY "Anyone can view active sponsor notices"
  ON public.sponsor_notices
  FOR SELECT
  USING (is_active = true);

-- Admin write policy
CREATE POLICY "Admins can manage sponsor notices"
  ON public.sponsor_notices
  FOR ALL
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));

-- Update trigger
CREATE TRIGGER update_sponsor_notices_updated_at
  BEFORE UPDATE ON public.sponsor_notices
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.sponsor_notices;

-- ============================================
-- Source: 20260118024449_38a57d9d-e062-460b-82e0-af2d10e9f0dd.sql
-- ============================================

-- Add notes column to saved_streaming_servers table for tournament/channel info
ALTER TABLE public.saved_streaming_servers 
ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT NULL;

-- ============================================
-- Source: 20260118025445_72d8736d-7a9c-4c2e-b3a2-388b36dc2cd8.sql
-- ============================================

-- Add new columns to banners table for match/tournament linking
ALTER TABLE public.banners 
  ADD COLUMN IF NOT EXISTS banner_type text DEFAULT 'custom' CHECK (banner_type IN ('match', 'tournament', 'custom')),
  ADD COLUMN IF NOT EXISTS match_id uuid REFERENCES public.matches(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS tournament_id uuid REFERENCES public.tournaments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS subtitle text,
  ADD COLUMN IF NOT EXISTS badge_type text DEFAULT 'none' CHECK (badge_type IN ('none', 'live', 'upcoming', 'watch_now'));

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_banners_match_id ON public.banners(match_id);
CREATE INDEX IF NOT EXISTS idx_banners_tournament_id ON public.banners(tournament_id);

COMMENT ON COLUMN public.banners.banner_type IS 'Type of banner: match, tournament, or custom link';
COMMENT ON COLUMN public.banners.badge_type IS 'Status badge to show: none, live, upcoming, watch_now';

-- ============================================
-- Source: 20260119024739_35dd994e-221a-4948-9918-2dcb01879b12.sql
-- ============================================

-- Add slider duration column to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS slider_duration_seconds INTEGER DEFAULT 6;

-- Also add to public view
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS slider_duration_seconds INTEGER DEFAULT 6;

-- ============================================
-- Source: 20260119030414_ce86cfd6-f077-404d-8932-811d186accfc.sql
-- ============================================

-- Add manual_status_override flag to matches table
-- When true, the update-match-status cron job will NOT auto-change the status
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS manual_status_override boolean DEFAULT false;

COMMENT ON COLUMN public.matches.manual_status_override IS 'When true, auto-status updates are disabled for this match';

-- Update site_settings_public view to include slider_duration_seconds
-- (fixing the sync trigger to include the new column)
DROP TRIGGER IF EXISTS sync_site_settings_trigger ON public.site_settings;

CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds;

  RETURN NEW;
END;
$function$;

-- Recreate the trigger
CREATE TRIGGER sync_site_settings_trigger
  AFTER INSERT OR UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.sync_site_settings_public_from_site_settings();

-- ============================================
-- Source: 20260120013127_5d067c7a-7cf4-4152-af3e-a79911d7b457.sql
-- ============================================

-- Change match_number from integer to text to allow custom values like "Round 7"
ALTER TABLE public.matches 
ALTER COLUMN match_number TYPE text USING match_number::text;

-- Update default value to null
ALTER TABLE public.matches 
ALTER COLUMN match_number SET DEFAULT NULL;

-- ============================================
-- Source: 20260120013825_226c69ca-3c5a-4420-a805-b27099071b0c.sql
-- ============================================

-- Allow null values in match_number column
ALTER TABLE public.matches 
ALTER COLUMN match_number DROP NOT NULL;

-- ============================================
-- Source: 20260120014953_4b21a3a9-19b0-47cc-894a-723a24fa9ed7.sql
-- ============================================

-- Add participating teams settings to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS show_participating_teams boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS participating_teams_position text DEFAULT 'before_matches',
ADD COLUMN IF NOT EXISTS custom_participating_teams jsonb DEFAULT NULL;

-- Position options: 'before_matches', 'after_matches', 'after_points_table', 'before_about', 'after_about'
-- custom_participating_teams format: [{"name": "Team Name", "logo_url": "optional_url"}, ...]

COMMENT ON COLUMN public.tournaments.show_participating_teams IS 'Toggle to show/hide participating teams section';
COMMENT ON COLUMN public.tournaments.participating_teams_position IS 'Position of participating teams: before_matches, after_matches, after_points_table, before_about, after_about';
COMMENT ON COLUMN public.tournaments.custom_participating_teams IS 'Custom list of participating teams with name and optional logo_url';

-- ============================================
-- Source: 20260124150240_1e13cc1a-be85-4161-8e59-084d8590bb58.sql
-- ============================================

-- Add admin_slug to site_settings
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS admin_slug text DEFAULT 'admin';
ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS admin_slug text DEFAULT 'admin';

-- Update sync function to include admin_slug
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug;

  RETURN NEW;
END;
$function$;

-- Create role_permissions table for granular permissions
CREATE TABLE IF NOT EXISTS public.role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role app_role NOT NULL,
  permission text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(role, permission)
);

-- Enable RLS
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

-- RLS policies for role_permissions
CREATE POLICY "Role permissions are viewable by authenticated users"
ON public.role_permissions
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Only super admins can manage role permissions"
ON public.role_permissions
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create user_permissions table for custom user-specific permissions override
CREATE TABLE IF NOT EXISTS public.user_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission text NOT NULL,
  granted boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(user_id, permission)
);

-- Enable RLS
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_permissions
CREATE POLICY "Users can view their own permissions"
ON public.user_permissions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Only admins can manage user permissions"
ON public.user_permissions
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Insert default permissions for roles
INSERT INTO public.role_permissions (role, permission) VALUES
  -- Admin has all permissions
  ('admin', 'manage_matches'),
  ('admin', 'manage_teams'),
  ('admin', 'manage_tournaments'),
  ('admin', 'manage_banners'),
  ('admin', 'manage_streaming'),
  ('admin', 'manage_settings'),
  ('admin', 'manage_users'),
  ('admin', 'manage_pages'),
  ('admin', 'manage_points_table'),
  ('admin', 'view_analytics'),
  -- Moderator has limited permissions
  ('moderator', 'manage_matches'),
  ('moderator', 'manage_teams'),
  ('moderator', 'manage_streaming'),
  ('moderator', 'manage_banners'),
  -- User role (if needed)
  ('user', 'view_analytics')
ON CONFLICT (role, permission) DO NOTHING;

-- Function to check if user has a specific permission
CREATE OR REPLACE FUNCTION public.has_permission(_user_id uuid, _permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    -- Check user-specific permission override (granted = true)
    SELECT 1 FROM public.user_permissions
    WHERE user_id = _user_id AND permission = _permission AND granted = true
  )
  OR (
    -- Check role-based permission (if no user-specific denial)
    NOT EXISTS (
      SELECT 1 FROM public.user_permissions
      WHERE user_id = _user_id AND permission = _permission AND granted = false
    )
    AND EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.role_permissions rp ON ur.role = rp.role
      WHERE ur.user_id = _user_id AND rp.permission = _permission
    )
  )
$$;

-- Allow admins to manage user_roles
CREATE POLICY "Admins can insert user roles"
ON public.user_roles
FOR INSERT
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update user roles"
ON public.user_roles
FOR UPDATE
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete user roles"
ON public.user_roles
FOR DELETE
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can view all user roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR has_role(auth.uid(), 'admin'::app_role));

-- ============================================
-- Source: 20260124161059_87398c65-1293-4353-8c0a-e164f8df765e.sql
-- ============================================

-- Drop existing SELECT policy on profiles
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON public.profiles;

-- Create new policy that allows admins to view all profiles, others view own
CREATE POLICY "Profiles viewable by owner and admins"
ON public.profiles
FOR SELECT
USING (
  auth.uid() = user_id 
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Also add policy for service role to manage profiles (for edge functions)
DROP POLICY IF EXISTS "Service role can manage profiles" ON public.profiles;

CREATE POLICY "Service role can manage profiles"
ON public.profiles
FOR ALL
USING (true)
WITH CHECK (true);

-- ============================================
-- Source: 20260124161317_436c1005-6b20-4619-b3fb-2702dfee5f2b.sql
-- ============================================

-- Create roles table for custom roles
CREATE TABLE IF NOT EXISTS public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  is_system boolean DEFAULT false,
  color text DEFAULT '#6b7280',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for roles table
CREATE POLICY "Roles are viewable by everyone"
ON public.roles FOR SELECT
USING (true);

CREATE POLICY "Only admins can manage roles"
ON public.roles FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Insert default system roles
INSERT INTO public.roles (name, display_name, description, is_system, color) VALUES
('admin', 'Admin', 'Full system access with all permissions', true, '#ef4444'),
('moderator', 'Moderator', 'Can manage content and moderate users', true, '#f59e0b'),
('user', 'User', 'Basic user access', true, '#22c55e')
ON CONFLICT (name) DO NOTHING;

-- Create custom_role_permissions table for custom roles
CREATE TABLE IF NOT EXISTS public.custom_role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid REFERENCES public.roles(id) ON DELETE CASCADE NOT NULL,
  permission text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE(role_id, permission)
);

-- Enable RLS
ALTER TABLE public.custom_role_permissions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Custom role permissions viewable by authenticated"
ON public.custom_role_permissions FOR SELECT
USING (true);

CREATE POLICY "Only admins can manage custom role permissions"
ON public.custom_role_permissions FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create user_custom_roles table for assigning custom roles to users
CREATE TABLE IF NOT EXISTS public.user_custom_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role_id uuid REFERENCES public.roles(id) ON DELETE CASCADE NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE(user_id, role_id)
);

-- Enable RLS
ALTER TABLE public.user_custom_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own custom roles"
ON public.user_custom_roles FOR SELECT
USING (auth.uid() = user_id OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Only admins can manage user custom roles"
ON public.user_custom_roles FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create function to check custom role permission
CREATE OR REPLACE FUNCTION public.has_custom_permission(_user_id uuid, _permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    -- Check user-specific permission override (granted = true)
    SELECT 1 FROM public.user_permissions
    WHERE user_id = _user_id AND permission = _permission AND granted = true
  )
  OR (
    -- Check if NOT denied by user-specific override
    NOT EXISTS (
      SELECT 1 FROM public.user_permissions
      WHERE user_id = _user_id AND permission = _permission AND granted = false
    )
    AND (
      -- Check original role-based permission (admin, moderator, user)
      EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.role_permissions rp ON ur.role = rp.role
        WHERE ur.user_id = _user_id AND rp.permission = _permission
      )
      OR
      -- Check custom role-based permission
      EXISTS (
        SELECT 1 FROM public.user_custom_roles ucr
        JOIN public.custom_role_permissions crp ON ucr.role_id = crp.role_id
        WHERE ucr.user_id = _user_id AND crp.permission = _permission
      )
    )
  )
$$;

-- Add trigger for updated_at
CREATE TRIGGER update_roles_updated_at
BEFORE UPDATE ON public.roles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- Source: 20260125043417_98e4aff2-05e6-486d-9872-ce691d2e825b.sql
-- ============================================

-- Add logo background color column to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN logo_background_color text DEFAULT '#1a1a2e';

-- Update the site_settings_public sync trigger to include this field if needed
COMMENT ON COLUMN public.tournaments.logo_background_color IS 'Custom background color for tournament logo display on match cards';

-- ============================================
-- Source: 20260125044029_20b3fe0c-a44e-4917-8554-9e101bd90500.sql
-- ============================================

-- Add logo_background_color column to teams table
ALTER TABLE public.teams 
ADD COLUMN logo_background_color text DEFAULT '#1a1a2e';

-- ============================================
-- Source: 20260125064357_44d60cfe-8c69-434f-af43-b03d8d6d12f7.sql
-- ============================================

-- Add display_order column to sports table
ALTER TABLE public.sports ADD COLUMN IF NOT EXISTS display_order integer DEFAULT 0;

-- Update existing sports with sequential order
UPDATE public.sports SET display_order = subquery.row_num
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM public.sports
) as subquery
WHERE public.sports.id = subquery.id;

-- ============================================
-- Source: 20260125065844_63fd7f2a-94f3-4464-96d4-98039b45519f.sql
-- ============================================

-- Add unique constraint on team name (exact match only) to prevent true duplicates
-- This allows "Manchester United" and "Manchester United Women" as separate teams
ALTER TABLE public.teams ADD CONSTRAINT teams_name_unique UNIQUE (name);

-- ============================================
-- Source: 20260125183211_841386d2-732e-40a1-ac04-508d09443253.sql
-- ============================================

-- Add football goal details columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS goals_team_a jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS goals_team_b jsonb DEFAULT '[]'::jsonb;

-- Add comment for clarity
COMMENT ON COLUMN public.matches.goals_team_a IS 'Array of goal events for team A: [{player, minute, assist?, type}]';
COMMENT ON COLUMN public.matches.goals_team_b IS 'Array of goal events for team B: [{player, minute, assist?, type}]';

-- ============================================
-- Source: 20260125191448_60f44888-b03b-48fb-91a4-53ad84fc16c2.sql
-- ============================================

-- Create match_substitutions table for football substitution tracking
CREATE TABLE public.match_substitutions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  player_out TEXT NOT NULL,
  player_in TEXT NOT NULL,
  minute TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.match_substitutions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Substitutions are viewable by everyone" 
ON public.match_substitutions 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert substitutions" 
ON public.match_substitutions 
FOR INSERT 
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can update substitutions" 
ON public.match_substitutions 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can delete substitutions" 
ON public.match_substitutions 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));

-- Create updated_at trigger
CREATE TRIGGER update_match_substitutions_updated_at
BEFORE UPDATE ON public.match_substitutions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Enable realtime for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.match_substitutions;

-- ============================================
-- Source: 20260126064239_d32865f9-db16-4ea6-9531-c8c677eebf55.sql
-- ============================================

-- Add score_source field to matches table for selecting API source per match
-- Options: 'api_cricket' (current RapidAPI), 'espn' (ESPN Cricinfo), 'manual' (manual entry only)
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS score_source text DEFAULT 'manual';

-- Add comment for clarity
COMMENT ON COLUMN public.matches.score_source IS 'Score source for this match: api_cricket (RapidAPI), espn (ESPN Cricinfo), or manual';

-- Add espn_event_id column for ESPN match linking
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS espn_event_id text;

COMMENT ON COLUMN public.matches.espn_event_id IS 'ESPN event ID for linking with ESPN Cricinfo API';

-- ============================================
-- Source: 20260126093342_12e96085-b5de-42f0-a539-9f3b9b92b2c5.sql
-- ============================================

-- Add RapidAPI endpoint configuration to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS rapidapi_endpoints jsonb DEFAULT '{
  "cricbuzz_host": "cricbuzz-cricket.p.rapidapi.com",
  "cricketapi_live_host": "cricketapi-live.p.rapidapi.com",
  "points_table_endpoint": "/series/v1/{series_id}/points-table",
  "squad_endpoint": "/mcenter/v1/{match_id}/hsquad",
  "scorecard_endpoint": "/mcenter/v1/{match_id}/scard",
  "live_matches_endpoint": "/matches/live",
  "match_squad_endpoint": "/squad/{match_id}"
}'::jsonb;

-- Sync to public settings
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS rapidapi_endpoints jsonb DEFAULT '{
  "cricbuzz_host": "cricbuzz-cricket.p.rapidapi.com",
  "cricketapi_live_host": "cricketapi-live.p.rapidapi.com",
  "points_table_endpoint": "/series/v1/{series_id}/points-table",
  "squad_endpoint": "/mcenter/v1/{match_id}/hsquad",
  "scorecard_endpoint": "/mcenter/v1/{match_id}/scard",
  "live_matches_endpoint": "/matches/live",
  "match_squad_endpoint": "/squad/{match_id}"
}'::jsonb;

-- Update the sync trigger function to include rapidapi_endpoints
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260128021423_438efa26-f14b-4e79-9960-b7b232dec18a.sql
-- ============================================

-- Create football_leagues table for caching ESPN leagues
CREATE TABLE public.football_leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  league_code TEXT UNIQUE NOT NULL,
  league_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.football_leagues ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Football leagues viewable by everyone" 
ON public.football_leagues 
FOR SELECT 
USING (true);

-- Admin management
CREATE POLICY "Admins can manage football leagues" 
ON public.football_leagues 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Service role access for edge function
CREATE POLICY "Service role can manage football leagues" 
ON public.football_leagues 
FOR ALL 
USING (true)
WITH CHECK (true);

-- ============================================
-- Source: 20260128022703_98474284-0833-4194-92e8-b46fb29b44c3.sql
-- ============================================

-- Add maintenance mode settings to site_settings table
ALTER TABLE public.site_settings
ADD COLUMN IF NOT EXISTS maintenance_mode BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS maintenance_title TEXT DEFAULT 'We''ll Be Right Back',
ADD COLUMN IF NOT EXISTS maintenance_subtitle TEXT DEFAULT 'Our site is currently undergoing scheduled maintenance.',
ADD COLUMN IF NOT EXISTS maintenance_description TEXT DEFAULT 'We''re working hard to improve your experience. Thank you for your patience.',
ADD COLUMN IF NOT EXISTS maintenance_estimated_time TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_show_countdown BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS maintenance_end_time TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_contact_email TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_social_message TEXT DEFAULT 'Follow us for updates';

-- Add to public view as well
ALTER TABLE public.site_settings_public
ADD COLUMN IF NOT EXISTS maintenance_mode BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS maintenance_title TEXT DEFAULT 'We''ll Be Right Back',
ADD COLUMN IF NOT EXISTS maintenance_subtitle TEXT DEFAULT 'Our site is currently undergoing scheduled maintenance.',
ADD COLUMN IF NOT EXISTS maintenance_description TEXT DEFAULT 'We''re working hard to improve your experience. Thank you for your patience.',
ADD COLUMN IF NOT EXISTS maintenance_estimated_time TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_show_countdown BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS maintenance_end_time TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_contact_email TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS maintenance_social_message TEXT DEFAULT 'Follow us for updates';

-- Update trigger to sync maintenance settings
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260131091856_25fc7a18-82a7-4f71-a5b8-3af7364a0c9c.sql
-- ============================================

-- Create cricket_series table (like football_leagues)
CREATE TABLE public.cricket_series (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    series_id text NOT NULL UNIQUE,
    series_name text NOT NULL,
    start_date date,
    end_date date,
    match_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    last_synced_at timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.cricket_series ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Cricket series viewable by everyone"
ON public.cricket_series FOR SELECT
USING (true);

CREATE POLICY "Admins can manage cricket series"
ON public.cricket_series FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Service role can manage cricket series"
ON public.cricket_series FOR ALL
USING (true)
WITH CHECK (true);

-- Index for faster lookups
CREATE INDEX idx_cricket_series_series_id ON public.cricket_series(series_id);
CREATE INDEX idx_cricket_series_is_active ON public.cricket_series(is_active);

-- ============================================
-- Source: 20260202002110_24abae15-e48e-4963-a971-e5de6b405ce3.sql
-- ============================================

-- Add disclaimer_text column to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS disclaimer_text text DEFAULT 'All content displayed here is from publicly available sources on the internet. We do not own or claim ownership of any cricket matches, streams, or highlights. This platform is for informational purposes only.';

-- Add disclaimer_text column to site_settings_public
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS disclaimer_text text DEFAULT 'All content displayed here is from publicly available sources on the internet. We do not own or claim ownership of any cricket matches, streams, or highlights. This platform is for informational purposes only.';

-- Update the trigger function to sync disclaimer_text
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message,
    disclaimer_text
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message,
    NEW.disclaimer_text
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260202002539_1924ae38-c8fc-453f-9892-b373ca636958.sql
-- ============================================

-- Add show_disclaimer column to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS show_disclaimer boolean DEFAULT true;

-- Add show_disclaimer column to site_settings_public
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS show_disclaimer boolean DEFAULT true;

-- Update the trigger function to sync show_disclaimer
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message,
    disclaimer_text,
    show_disclaimer
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message,
    NEW.disclaimer_text,
    NEW.show_disclaimer
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text,
    show_disclaimer = EXCLUDED.show_disclaimer;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260202071750_7dd79337-689b-4ac3-a00b-609e1a1c9873.sql
-- ============================================

-- Function to automatically reassign clean slug when match is completed
CREATE OR REPLACE FUNCTION public.reassign_slug_on_match_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_base_slug TEXT;
  v_next_match_id UUID;
  v_next_match_slug TEXT;
  v_slug_number INTEGER;
BEGIN
  -- Only process if status changed to 'completed' and match has a slug
  IF NEW.status = 'completed' 
     AND (OLD.status IS NULL OR OLD.status != 'completed') 
     AND NEW.slug IS NOT NULL 
  THEN
    -- Check if this is a clean slug (ends with -live, not -live-N)
    IF NEW.slug ~ '^.+-live$' AND NEW.slug !~ '^.+-live-\d+$' THEN
      v_base_slug := NEW.slug;
      
      -- Find the next upcoming/live match with numbered slug (e.g., team-a-vs-team-b-live-2)
      SELECT id, slug INTO v_next_match_id, v_next_match_slug
      FROM matches
      WHERE slug ~ ('^' || regexp_replace(v_base_slug, '-', '\\-', 'g') || '-\d+$')
        AND status IN ('upcoming', 'live')
        AND id != NEW.id
      ORDER BY 
        CASE WHEN status = 'live' THEN 0 ELSE 1 END,
        match_start_time ASC NULLS LAST,
        match_date ASC,
        match_time ASC
      LIMIT 1;
      
      IF v_next_match_id IS NOT NULL THEN
        -- Extract the number from the next match's slug
        v_slug_number := (regexp_match(v_next_match_slug, '-(\d+)$'))[1]::INTEGER;
        
        -- Give the clean slug to the next match
        UPDATE matches SET slug = v_base_slug WHERE id = v_next_match_id;
        
        -- Give the completed match a numbered slug
        UPDATE matches SET slug = v_base_slug || '-' || v_slug_number WHERE id = NEW.id;
        
        -- Update NEW to reflect the change (for the trigger return)
        NEW.slug := v_base_slug || '-' || v_slug_number;
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Create trigger to auto-reassign slug on match completion
DROP TRIGGER IF EXISTS trigger_reassign_slug_on_complete ON matches;
CREATE TRIGGER trigger_reassign_slug_on_complete
  BEFORE UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION reassign_slug_on_match_complete();

-- ============================================
-- Source: 20260202110936_c2806dea-b808-4b33-b5c9-dc2bf4f8fa7f.sql
-- ============================================

-- Add group_name column to tournament_points_table for group-based tournaments
ALTER TABLE public.tournament_points_table 
ADD COLUMN group_name text DEFAULT NULL;

-- Add comment for clarity
COMMENT ON COLUMN public.tournament_points_table.group_name IS 'Group name for group-stage tournaments (e.g., Group A, Group B)';

-- ============================================
-- Source: 20260203084605_f34eefa0-aa5b-44c0-a96d-2dc39b992214.sql
-- ============================================

-- Add is_bench column to match_playing_xi table
ALTER TABLE public.match_playing_xi 
ADD COLUMN is_bench boolean DEFAULT false;

-- Add comment for clarity
COMMENT ON COLUMN public.match_playing_xi.is_bench IS 'True if player is on bench (part of squad but not in Playing XI)';

-- ============================================
-- Source: 20260203093934_f9860d8b-b43f-40e5-8fed-b79990434bf3.sql
-- ============================================

-- Add show_playing_xi column to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS show_playing_xi BOOLEAN DEFAULT false;

-- ============================================
-- Source: 20260203101530_7bd245d5-2aff-4790-88d1-2c02844a822c.sql
-- ============================================

-- Add change_status column to track player IN/OUT status compared to last match
ALTER TABLE public.match_playing_xi 
ADD COLUMN IF NOT EXISTS change_status text DEFAULT NULL;

-- Add comment for clarity
COMMENT ON COLUMN public.match_playing_xi.change_status IS 'Indicates if player is new (in) or dropped (out) compared to last match. Values: in, out, null (unchanged)';

-- ============================================
-- Source: 20260203105137_badca3b1-dee8-480f-a126-6ca37911e734.sql
-- ============================================

-- Add column to store how many days of completed matches to show on homepage
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS homepage_completed_days integer DEFAULT 2;

-- Add the same column to site_settings_public table
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS homepage_completed_days integer DEFAULT 2;

-- Update the sync trigger function to include the new column
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message,
    disclaimer_text,
    show_disclaimer,
    homepage_completed_days
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message,
    NEW.disclaimer_text,
    NEW.show_disclaimer,
    NEW.homepage_completed_days
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text,
    show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days;

  RETURN NEW;
END;
$function$;

-- Add comment
COMMENT ON COLUMN public.site_settings.homepage_completed_days IS 'Number of days of completed matches to show on homepage';

-- ============================================
-- Source: 20260203132108_a3b209c7-bee0-4c8c-b73e-3350e1ea1317.sql
-- ============================================

-- Create channels table
CREATE TABLE public.channels (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  logo_url TEXT,
  logo_background_color TEXT DEFAULT '#1a1a2e',
  description TEXT,
  seo_title TEXT,
  seo_description TEXT,
  seo_keywords TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create channel_streaming_servers table
CREATE TABLE public.channel_streaming_servers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  server_name TEXT NOT NULL,
  server_url TEXT NOT NULL,
  server_type TEXT NOT NULL DEFAULT 'iframe',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  referer_value TEXT,
  origin_value TEXT,
  cookie_value TEXT,
  user_agent TEXT,
  drm_license_url TEXT,
  drm_scheme TEXT,
  player_type TEXT DEFAULT 'hls',
  clearkey_key_id TEXT,
  clearkey_key TEXT,
  ad_block_enabled BOOLEAN DEFAULT false,
  is_working BOOLEAN DEFAULT true,
  original_display_order INTEGER,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channel_streaming_servers ENABLE ROW LEVEL SECURITY;

-- RLS policies for channels
CREATE POLICY "Channels are viewable by everyone" 
ON public.channels 
FOR SELECT 
USING (is_active = true);

CREATE POLICY "Admins can manage channels" 
ON public.channels 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- RLS policies for channel_streaming_servers
CREATE POLICY "Active channel servers are viewable by everyone" 
ON public.channel_streaming_servers 
FOR SELECT 
USING (is_active = true);

CREATE POLICY "Admins can manage channel servers" 
ON public.channel_streaming_servers 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create indexes
CREATE INDEX idx_channels_display_order ON public.channels(display_order);
CREATE INDEX idx_channels_slug ON public.channels(slug);
CREATE INDEX idx_channel_servers_channel_id ON public.channel_streaming_servers(channel_id);
CREATE INDEX idx_channel_servers_display_order ON public.channel_streaming_servers(display_order);

-- Create triggers for updated_at
CREATE TRIGGER update_channels_updated_at
BEFORE UPDATE ON public.channels
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_channel_streaming_servers_updated_at
BEFORE UPDATE ON public.channel_streaming_servers
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- Source: 20260203140026_6bec0709-088a-410d-9e06-674b4228124e.sql
-- ============================================

-- Add homepage_channels_limit to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS homepage_channels_limit integer DEFAULT 8;

-- Add homepage_channels_limit to site_settings_public
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS homepage_channels_limit integer DEFAULT 8;

-- ============================================
-- Source: 20260203140653_cc25a75a-de85-4c6e-b62b-bff215378b6b.sql
-- ============================================

-- Create custom_menus table for menu management
CREATE TABLE public.custom_menus (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  url TEXT,
  icon_name TEXT,
  parent_id UUID REFERENCES public.custom_menus(id) ON DELETE CASCADE,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  open_in_new_tab BOOLEAN DEFAULT false,
  menu_type TEXT DEFAULT 'link',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.custom_menus ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Custom menus are viewable by everyone"
ON public.custom_menus
FOR SELECT
USING (is_active = true);

CREATE POLICY "Admins can manage custom menus"
ON public.custom_menus
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create index for faster queries
CREATE INDEX idx_custom_menus_parent ON public.custom_menus(parent_id);
CREATE INDEX idx_custom_menus_order ON public.custom_menus(display_order);

-- ============================================
-- Source: 20260204163720_608c06c3-4f49-4604-8818-11ae0015554d.sql
-- ============================================

-- Add new columns to site_settings_public table as well
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS tournament_page_ad_positions jsonb DEFAULT '{"before_matches": true, "after_matches": true, "sidebar": true, "before_points_table": true, "after_points_table": true}'::jsonb;

ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS multiple_ad_codes jsonb DEFAULT '{}'::jsonb;

-- ============================================
-- Source: 20260205011805_b2035d58-82b4-4626-9670-2e718aa96066.sql
-- ============================================

-- Add multiple_ad_codes column to site_settings table
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS multiple_ad_codes jsonb DEFAULT '{}'::jsonb;

-- Update the sync trigger function to include multiple_ad_codes
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message,
    disclaimer_text,
    show_disclaimer,
    homepage_completed_days,
    multiple_ad_codes
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message,
    NEW.disclaimer_text,
    NEW.show_disclaimer,
    NEW.homepage_completed_days,
    NEW.multiple_ad_codes
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text,
    show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260205012135_e92553fb-831b-4b37-86b9-4ec74350a708.sql
-- ============================================

-- Add tournament_page_ad_positions column to site_settings table
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS tournament_page_ad_positions jsonb DEFAULT '{"sidebar": true, "after_matches": true, "before_matches": true, "after_points_table": true, "before_points_table": true}'::jsonb;

-- Update the sync trigger function to include tournament_page_ad_positions
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id,
    site_name,
    site_title,
    site_description,
    site_keywords,
    logo_url,
    favicon_url,
    og_image_url,
    footer_text,
    google_analytics_id,
    created_at,
    updated_at,
    header_ad_code,
    sidebar_ad_code,
    footer_ad_code,
    in_article_ad_code,
    popup_ad_code,
    ads_enabled,
    google_adsense_id,
    canonical_url,
    robots_txt,
    schema_org_enabled,
    twitter_handle,
    facebook_app_id,
    telegram_link,
    social_links,
    cricket_api_enabled,
    ads_txt_content,
    custom_header_code,
    custom_footer_code,
    match_page_ad_positions,
    api_cricket_enabled,
    api_sync_interval_seconds,
    slider_duration_seconds,
    admin_slug,
    rapidapi_endpoints,
    maintenance_mode,
    maintenance_title,
    maintenance_subtitle,
    maintenance_description,
    maintenance_estimated_time,
    maintenance_show_countdown,
    maintenance_end_time,
    maintenance_contact_email,
    maintenance_social_message,
    disclaimer_text,
    show_disclaimer,
    homepage_completed_days,
    multiple_ad_codes,
    tournament_page_ad_positions
  ) VALUES (
    NEW.id,
    NEW.site_name,
    NEW.site_title,
    NEW.site_description,
    NEW.site_keywords,
    NEW.logo_url,
    NEW.favicon_url,
    NEW.og_image_url,
    NEW.footer_text,
    NEW.google_analytics_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.header_ad_code,
    NEW.sidebar_ad_code,
    NEW.footer_ad_code,
    NEW.in_article_ad_code,
    NEW.popup_ad_code,
    NEW.ads_enabled,
    NEW.google_adsense_id,
    NEW.canonical_url,
    NEW.robots_txt,
    NEW.schema_org_enabled,
    NEW.twitter_handle,
    NEW.facebook_app_id,
    NEW.telegram_link,
    NEW.social_links,
    NEW.cricket_api_enabled,
    NEW.ads_txt_content,
    NEW.custom_header_code,
    NEW.custom_footer_code,
    NEW.match_page_ad_positions,
    NEW.api_cricket_enabled,
    NEW.api_sync_interval_seconds,
    NEW.slider_duration_seconds,
    NEW.admin_slug,
    NEW.rapidapi_endpoints,
    NEW.maintenance_mode,
    NEW.maintenance_title,
    NEW.maintenance_subtitle,
    NEW.maintenance_description,
    NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown,
    NEW.maintenance_end_time,
    NEW.maintenance_contact_email,
    NEW.maintenance_social_message,
    NEW.disclaimer_text,
    NEW.show_disclaimer,
    NEW.homepage_completed_days,
    NEW.multiple_ad_codes,
    NEW.tournament_page_ad_positions
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name,
    site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description,
    site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url,
    favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url,
    footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code,
    footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code,
    popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled,
    google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url,
    robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled,
    twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id,
    telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links,
    cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content,
    custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code,
    match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled,
    api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds,
    admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints,
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title,
    maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description,
    maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown,
    maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email,
    maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text,
    show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260205120151_5afdf4c6-38a9-4f52-8d50-d29fcdd06fb6.sql
-- ============================================

-- Add manual toss columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS toss_winner_id UUID REFERENCES public.teams(id),
ADD COLUMN IF NOT EXISTS toss_decision TEXT CHECK (toss_decision IN ('bat', 'bowl'));

-- Add index for toss queries
CREATE INDEX IF NOT EXISTS idx_matches_toss_winner ON public.matches(toss_winner_id) WHERE toss_winner_id IS NOT NULL;

-- ============================================
-- Source: 20260208020530_900e52ce-5e74-40b7-a755-6617c251de17.sql
-- ============================================


-- Add points table auto sync time to site_settings
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS points_table_sync_time text DEFAULT '03:00';

-- Add points table auto sync enabled flag
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS points_table_auto_sync_enabled boolean DEFAULT false;

-- Add same columns to site_settings_public
ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS points_table_sync_time text DEFAULT '03:00';

ALTER TABLE public.site_settings_public 
ADD COLUMN IF NOT EXISTS points_table_auto_sync_enabled boolean DEFAULT false;

-- Update the sync trigger to include new columns
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, multiple_ad_codes, tournament_page_ad_positions,
    points_table_sync_time, points_table_auto_sync_enabled
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.multiple_ad_codes, NEW.tournament_page_ad_positions,
    NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days, multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled;

  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260208021715_2d17f49a-1bde-47dd-a9b4-597b0fbf798c.sql
-- ============================================

ALTER TABLE public.tournaments ADD COLUMN show_points_table boolean DEFAULT true;

-- ============================================
-- Source: 20260208023100_52f6191d-05c2-4b18-a674-3dd459b454bb.sql
-- ============================================

-- Add per-tournament points table sync time
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS points_table_sync_time text DEFAULT NULL;

-- Add comment for clarity
COMMENT ON COLUMN public.tournaments.points_table_sync_time IS 'Per-tournament auto-sync time in ISO format with timezone offset, e.g. 03:00+06:00';


-- ============================================
-- Source: 20260208025533_a4f4df72-47c0-44be-b60f-c3c6e3434459.sql
-- ============================================


CREATE OR REPLACE FUNCTION public.recalculate_tournament_positions(p_tournament_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Check if caller is admin or service role
  IF NOT has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Only admins can recalculate tournament positions';
  END IF;

  -- Only update NRR if we have the overs data to calculate it
  UPDATE tournament_points_table SET
    net_run_rate = CASE 
      WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
        ROUND(((COALESCE(runs_scored, 0)::numeric / overs_faced) - (COALESCE(runs_conceded, 0)::numeric / overs_bowled))::numeric, 3)
      ELSE 
        net_run_rate
    END
  WHERE tournament_id = p_tournament_id;
  
  -- Recalculate positions WITHIN each group separately
  WITH ranked_teams AS (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        PARTITION BY COALESCE(group_name, '__no_group__')
        ORDER BY 
          COALESCE(points, 0) DESC,
          COALESCE(net_run_rate, 0) DESC,
          COALESCE(won, 0) DESC
      ) as new_position
    FROM tournament_points_table
    WHERE tournament_id = p_tournament_id
  )
  UPDATE tournament_points_table t
  SET position = r.new_position
  FROM ranked_teams r
  WHERE t.id = r.id;
END;
$function$;


-- ============================================
-- Source: 20260208025642_d11abc31-f638-4494-b67f-71887202eb6e.sql
-- ============================================


CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
      WHEN 'tied' THEN
        v_is_tied := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
      ELSE
        RETURN NEW;
    END CASE;
    
    FOR v_innings_record IN 
      SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
      FROM match_innings 
      WHERE match_id = NEW.id
    LOOP
      IF v_innings_record.batting_team_id = v_team_a_id THEN
        v_team_a_runs := v_team_a_runs + v_innings_record.runs;
        v_team_a_overs := v_team_a_overs + v_innings_record.overs;
      ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
        v_team_b_runs := v_team_b_runs + v_innings_record.runs;
        v_team_b_overs := v_team_b_overs + v_innings_record.overs;
      END IF;
    END LOOP;
    
    -- Insert/Update team A
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, v_team_a_id, 1,
      CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      0, v_team_a_runs, v_team_a_overs, v_team_b_runs, v_team_b_overs,
      CASE 
        WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_a_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_a_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_b_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_b_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_a_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0)))
        WHEN v_loser_id = v_team_a_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1))
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Insert/Update team B
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, v_team_b_id, 1,
      CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      0, v_team_b_runs, v_team_b_overs, v_team_a_runs, v_team_a_overs,
      CASE 
        WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_b_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_b_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_a_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_a_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_b_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0)))
        WHEN v_loser_id = v_team_b_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1))
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Update NRR for both teams
    UPDATE tournament_points_table SET
      net_run_rate = CASE 
        WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
          ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
        ELSE 0
      END
    WHERE tournament_id = v_tournament_id 
      AND team_id IN (v_team_a_id, v_team_b_id);
    
    -- Auto-update positions WITHIN each group
    WITH ranked_teams AS (
      SELECT 
        id,
        ROW_NUMBER() OVER (
          PARTITION BY COALESCE(group_name, '__no_group__')
          ORDER BY 
            COALESCE(points, 0) DESC,
            COALESCE(net_run_rate, 0) DESC,
            COALESCE(won, 0) DESC
        ) as new_position
      FROM tournament_points_table
      WHERE tournament_id = v_tournament_id
    )
    UPDATE tournament_points_table t
    SET position = r.new_position
    FROM ranked_teams r
    WHERE t.id = r.id;
    
  END IF;
  
  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260208033342_87f086a5-6eb1-4dd9-94dd-1691b461e21d.sql
-- ============================================

-- Create a trigger function that auto-calculates football score from goals arrays
CREATE OR REPLACE FUNCTION public.auto_calculate_football_score()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_sport_name TEXT;
  v_goals_a JSONB;
  v_goals_b JSONB;
  v_score_a INTEGER := 0;
  v_score_b INTEGER := 0;
  v_goal JSONB;
BEGIN
  -- Only process if goals changed
  IF (NEW.goals_team_a IS NOT DISTINCT FROM OLD.goals_team_a) 
     AND (NEW.goals_team_b IS NOT DISTINCT FROM OLD.goals_team_b) THEN
    RETURN NEW;
  END IF;

  -- Check if this is a football match
  IF NEW.sport_id IS NOT NULL THEN
    SELECT name INTO v_sport_name FROM sports WHERE id = NEW.sport_id;
    IF v_sport_name IS NULL OR v_sport_name NOT ILIKE '%football%' THEN
      RETURN NEW;
    END IF;
  ELSE
    RETURN NEW;
  END IF;

  v_goals_a := COALESCE(NEW.goals_team_a, '[]'::jsonb);
  v_goals_b := COALESCE(NEW.goals_team_b, '[]'::jsonb);

  -- Count goals for team A: regular goals + own goals by team B
  FOR v_goal IN SELECT * FROM jsonb_array_elements(v_goals_a)
  LOOP
    IF (v_goal->>'type') != 'own_goal' THEN
      v_score_a := v_score_a + 1;
    ELSE
      v_score_b := v_score_b + 1;
    END IF;
  END LOOP;

  -- Count goals for team B: regular goals + own goals by team A
  FOR v_goal IN SELECT * FROM jsonb_array_elements(v_goals_b)
  LOOP
    IF (v_goal->>'type') != 'own_goal' THEN
      v_score_b := v_score_b + 1;
    ELSE
      v_score_a := v_score_a + 1;
    END IF;
  END LOOP;

  -- Update scores
  NEW.score_a := v_score_a::text;
  NEW.score_b := v_score_b::text;

  RETURN NEW;
END;
$$;

-- Create the trigger (BEFORE UPDATE so it modifies the row in-place)
DROP TRIGGER IF EXISTS auto_calculate_football_score_trigger ON matches;
CREATE TRIGGER auto_calculate_football_score_trigger
  BEFORE UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_calculate_football_score();


-- ============================================
-- Source: 20260208033836_67503f73-d353-4ab4-946c-d339895a7464.sql
-- ============================================

-- Fix sync trigger to include homepage_channels_limit and ad_block_rules
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes, 
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes, 
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days, 
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled;

  RETURN NEW;
END;
$$;

-- Now manually sync the current value
UPDATE public.site_settings_public sp
SET homepage_channels_limit = s.homepage_channels_limit
FROM public.site_settings s
WHERE sp.id = s.id;

-- ============================================
-- Source: 20260208061020_9695aebf-db55-4d77-bdef-5ed7acacf117.sql
-- ============================================


-- Add cricapi_match_id column to matches table
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS cricapi_match_id text DEFAULT NULL;

-- Add index for cricapi_match_id lookups
CREATE INDEX IF NOT EXISTS idx_matches_cricapi_match_id ON public.matches(cricapi_match_id) WHERE cricapi_match_id IS NOT NULL;


-- ============================================
-- Source: 20260208064311_f718df9e-bf1a-4787-a43b-7266ed259558.sql
-- ============================================

ALTER TABLE public.match_playing_xi ADD COLUMN player_image text DEFAULT NULL;

-- ============================================
-- Source: 20260208150356_245ec586-c480-4c07-96e0-ab4020fb9819.sql
-- ============================================


-- Add per-tournament points table sync toggles
ALTER TABLE public.tournaments 
  ADD COLUMN IF NOT EXISTS points_table_daily_sync_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS points_table_on_complete_sync_enabled boolean DEFAULT false;

-- Update the match completion trigger to also call API sync when enabled
CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
  v_on_complete_sync BOOLEAN := false;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Check if on-complete sync is enabled for this tournament
    SELECT points_table_on_complete_sync_enabled INTO v_on_complete_sync
    FROM tournaments WHERE id = v_tournament_id;
    
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
      WHEN 'tied' THEN
        v_is_tied := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
      ELSE
        RETURN NEW;
    END CASE;
    
    FOR v_innings_record IN 
      SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
      FROM match_innings 
      WHERE match_id = NEW.id
    LOOP
      IF v_innings_record.batting_team_id = v_team_a_id THEN
        v_team_a_runs := v_team_a_runs + v_innings_record.runs;
        v_team_a_overs := v_team_a_overs + v_innings_record.overs;
      ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
        v_team_b_runs := v_team_b_runs + v_innings_record.runs;
        v_team_b_overs := v_team_b_overs + v_innings_record.overs;
      END IF;
    END LOOP;
    
    -- Insert/Update team A
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, v_team_a_id, 1,
      CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      0, v_team_a_runs, v_team_a_overs, v_team_b_runs, v_team_b_overs,
      CASE 
        WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_a_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_a_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_b_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_b_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_a_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0)))
        WHEN v_loser_id = v_team_a_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1))
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Insert/Update team B
    INSERT INTO tournament_points_table (
      tournament_id, team_id, played, won, lost, tied, no_result, points, position,
      runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
    )
    VALUES (
      v_tournament_id, v_team_b_id, 1,
      CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      0, v_team_b_runs, v_team_b_overs, v_team_a_runs, v_team_a_overs,
      CASE 
        WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
        WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
        ELSE '{}'::jsonb
      END
    )
    ON CONFLICT (tournament_id, team_id) DO UPDATE SET
      played = tournament_points_table.played + 1,
      won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
      lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
      tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
      no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
      points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
      runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_b_runs,
      overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_b_overs,
      runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_a_runs,
      overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_a_overs,
      head_to_head = CASE 
        WHEN v_winner_id = v_team_b_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0)))
        WHEN v_loser_id = v_team_b_id THEN 
          jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
            jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1))
        ELSE tournament_points_table.head_to_head
      END,
      updated_at = now();
    
    -- Update NRR for both teams
    UPDATE tournament_points_table SET
      net_run_rate = CASE 
        WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
          ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
        ELSE 0
      END
    WHERE tournament_id = v_tournament_id 
      AND team_id IN (v_team_a_id, v_team_b_id);
    
    -- Auto-update positions WITHIN each group
    WITH ranked_teams AS (
      SELECT 
        id,
        ROW_NUMBER() OVER (
          PARTITION BY COALESCE(group_name, '__no_group__')
          ORDER BY 
            COALESCE(points, 0) DESC,
            COALESCE(net_run_rate, 0) DESC,
            COALESCE(won, 0) DESC
        ) as new_position
      FROM tournament_points_table
      WHERE tournament_id = v_tournament_id
    )
    UPDATE tournament_points_table t
    SET position = r.new_position
    FROM ranked_teams r
    WHERE t.id = r.id;
    
    -- If on-complete API sync is enabled, trigger the sync-points-table function
    IF v_on_complete_sync THEN
      BEGIN
        PERFORM net.http_post(
          url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-points-table',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcXRlZm9ydW1qZHVnaWZ4cnlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NDY5NjQsImV4cCI6MjA4MjEyMjk2NH0.TzRAPhPWC6WN_IR24qEWA8TznqlrqPirJBdDmWyT9n8"}'::jsonb,
          body := jsonb_build_object('tournamentId', v_tournament_id)
        );
        RAISE LOG 'Points table on-complete sync triggered for tournament %', v_tournament_id;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Failed to trigger on-complete sync for tournament %: %', v_tournament_id, SQLERRM;
      END;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260209093901_657470de-27c4-46ac-bf15-fda576f48bcf.sql
-- ============================================


CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
  v_on_complete_sync BOOLEAN := false;
  v_has_valid_result BOOLEAN := false;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Check if on-complete sync is enabled for this tournament
    SELECT points_table_on_complete_sync_enabled INTO v_on_complete_sync
    FROM tournaments WHERE id = v_tournament_id;
    
    -- Determine if we have a valid match result for direct points update
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
        v_has_valid_result := true;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
        v_has_valid_result := true;
      WHEN 'tied' THEN
        v_is_tied := true;
        v_has_valid_result := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
        v_has_valid_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
        v_has_valid_result := true;
      ELSE
        v_has_valid_result := false;
    END CASE;
    
    -- If we have a valid result, update points directly
    IF v_has_valid_result THEN
      FOR v_innings_record IN 
        SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
        FROM match_innings 
        WHERE match_id = NEW.id
      LOOP
        IF v_innings_record.batting_team_id = v_team_a_id THEN
          v_team_a_runs := v_team_a_runs + v_innings_record.runs;
          v_team_a_overs := v_team_a_overs + v_innings_record.overs;
        ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
          v_team_b_runs := v_team_b_runs + v_innings_record.runs;
          v_team_b_overs := v_team_b_overs + v_innings_record.overs;
        END IF;
      END LOOP;
      
      -- Insert/Update team A
      INSERT INTO tournament_points_table (
        tournament_id, team_id, played, won, lost, tied, no_result, points, position,
        runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
      )
      VALUES (
        v_tournament_id, v_team_a_id, 1,
        CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
        CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
        CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        0, v_team_a_runs, v_team_a_overs, v_team_b_runs, v_team_b_overs,
        CASE 
          WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
          WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
          ELSE '{}'::jsonb
        END
      )
      ON CONFLICT (tournament_id, team_id) DO UPDATE SET
        played = tournament_points_table.played + 1,
        won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
        lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
        tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_a_runs,
        overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_a_overs,
        runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_b_runs,
        overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_b_overs,
        head_to_head = CASE 
          WHEN v_winner_id = v_team_a_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0)))
          WHEN v_loser_id = v_team_a_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1))
          ELSE tournament_points_table.head_to_head
        END,
        updated_at = now();
      
      -- Insert/Update team B
      INSERT INTO tournament_points_table (
        tournament_id, team_id, played, won, lost, tied, no_result, points, position,
        runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
      )
      VALUES (
        v_tournament_id, v_team_b_id, 1,
        CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
        CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
        CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        0, v_team_b_runs, v_team_b_overs, v_team_a_runs, v_team_a_overs,
        CASE 
          WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
          WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
          ELSE '{}'::jsonb
        END
      )
      ON CONFLICT (tournament_id, team_id) DO UPDATE SET
        played = tournament_points_table.played + 1,
        won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
        lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
        tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_b_runs,
        overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_b_overs,
        runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_a_runs,
        overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_a_overs,
        head_to_head = CASE 
          WHEN v_winner_id = v_team_b_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0)))
          WHEN v_loser_id = v_team_b_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1))
          ELSE tournament_points_table.head_to_head
        END,
        updated_at = now();
      
      -- Update NRR for both teams
      UPDATE tournament_points_table SET
        net_run_rate = CASE 
          WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
            ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
          ELSE 0
        END
      WHERE tournament_id = v_tournament_id 
        AND team_id IN (v_team_a_id, v_team_b_id);
      
      -- Auto-update positions WITHIN each group
      WITH ranked_teams AS (
        SELECT 
          id,
          ROW_NUMBER() OVER (
            PARTITION BY COALESCE(group_name, '__no_group__')
            ORDER BY 
              COALESCE(points, 0) DESC,
              COALESCE(net_run_rate, 0) DESC,
              COALESCE(won, 0) DESC
          ) as new_position
        FROM tournament_points_table
        WHERE tournament_id = v_tournament_id
      )
      UPDATE tournament_points_table t
      SET position = r.new_position
      FROM ranked_teams r
      WHERE t.id = r.id;
    END IF;
    
    -- ALWAYS trigger API sync if on-complete sync is enabled, regardless of match_result
    -- This ensures points table gets updated from API even when match_result is NULL
    IF v_on_complete_sync THEN
      BEGIN
        PERFORM net.http_post(
          url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-points-table',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcXRlZm9ydW1qZHVnaWZ4cnlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NDY5NjQsImV4cCI6MjA4MjEyMjk2NH0.TzRAPhPWC6WN_IR24qEWA8TznqlrqPirJBdDmWyT9n8"}'::jsonb,
          body := jsonb_build_object('tournamentId', v_tournament_id)
        );
        RAISE LOG 'Points table on-complete sync triggered for tournament % (match_result: %)', v_tournament_id, COALESCE(v_match_result, 'NULL');
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Failed to trigger on-complete sync for tournament %: %', v_tournament_id, SQLERRM;
      END;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260209133526_f78e7719-1fa9-4e39-ab19-519acce1c1c0.sql
-- ============================================

CREATE OR REPLACE FUNCTION public.recalculate_tournament_positions(p_tournament_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only update NRR if we have the overs data to calculate it
  UPDATE tournament_points_table SET
    net_run_rate = CASE 
      WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
        ROUND(((COALESCE(runs_scored, 0)::numeric / overs_faced) - (COALESCE(runs_conceded, 0)::numeric / overs_bowled))::numeric, 3)
      ELSE 
        net_run_rate
    END
  WHERE tournament_id = p_tournament_id;
  
  -- Recalculate positions WITHIN each group separately
  WITH ranked_teams AS (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        PARTITION BY COALESCE(group_name, '__no_group__')
        ORDER BY 
          COALESCE(points, 0) DESC,
          COALESCE(net_run_rate, 0) DESC,
          COALESCE(won, 0) DESC
      ) as new_position
    FROM tournament_points_table
    WHERE tournament_id = p_tournament_id
  )
  UPDATE tournament_points_table t
  SET position = r.new_position
  FROM ranked_teams r
  WHERE t.id = r.id;
END;
$$;

-- ============================================
-- Source: 20260209182233_37e24aa6-5014-466a-8b91-455d1979109b.sql
-- ============================================


CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
  v_on_complete_sync BOOLEAN := false;
  v_has_valid_result BOOLEAN := false;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    SELECT points_table_on_complete_sync_enabled INTO v_on_complete_sync
    FROM tournaments WHERE id = v_tournament_id;
    
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
        v_has_valid_result := true;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
        v_has_valid_result := true;
      WHEN 'tied' THEN
        v_is_tied := true;
        v_has_valid_result := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
        v_has_valid_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
        v_has_valid_result := true;
      ELSE
        v_has_valid_result := false;
    END CASE;
    
    IF v_has_valid_result THEN
      FOR v_innings_record IN 
        SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
        FROM match_innings 
        WHERE match_id = NEW.id
      LOOP
        IF v_innings_record.batting_team_id = v_team_a_id THEN
          v_team_a_runs := v_team_a_runs + v_innings_record.runs;
          v_team_a_overs := v_team_a_overs + v_innings_record.overs;
        ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
          v_team_b_runs := v_team_b_runs + v_innings_record.runs;
          v_team_b_overs := v_team_b_overs + v_innings_record.overs;
        END IF;
      END LOOP;
      
      INSERT INTO tournament_points_table (
        tournament_id, team_id, played, won, lost, tied, no_result, points, position,
        runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
      )
      VALUES (
        v_tournament_id, v_team_a_id, 1,
        CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
        CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
        CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        0, v_team_a_runs, v_team_a_overs, v_team_b_runs, v_team_b_overs,
        CASE 
          WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
          WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
          ELSE '{}'::jsonb
        END
      )
      ON CONFLICT (tournament_id, team_id) DO UPDATE SET
        played = tournament_points_table.played + 1,
        won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
        lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
        tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_a_runs,
        overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_a_overs,
        runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_b_runs,
        overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_b_overs,
        head_to_head = CASE 
          WHEN v_winner_id = v_team_a_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0)))
          WHEN v_loser_id = v_team_a_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1))
          ELSE tournament_points_table.head_to_head
        END,
        updated_at = now();
      
      INSERT INTO tournament_points_table (
        tournament_id, team_id, played, won, lost, tied, no_result, points, position,
        runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
      )
      VALUES (
        v_tournament_id, v_team_b_id, 1,
        CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
        CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
        CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        0, v_team_b_runs, v_team_b_overs, v_team_a_runs, v_team_a_overs,
        CASE 
          WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
          WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
          ELSE '{}'::jsonb
        END
      )
      ON CONFLICT (tournament_id, team_id) DO UPDATE SET
        played = tournament_points_table.played + 1,
        won = tournament_points_table.won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
        lost = tournament_points_table.lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
        tied = tournament_points_table.tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
        no_result = tournament_points_table.no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
        points = tournament_points_table.points + CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
        runs_scored = COALESCE(tournament_points_table.runs_scored, 0) + v_team_b_runs,
        overs_faced = COALESCE(tournament_points_table.overs_faced, 0) + v_team_b_overs,
        runs_conceded = COALESCE(tournament_points_table.runs_conceded, 0) + v_team_a_runs,
        overs_bowled = COALESCE(tournament_points_table.overs_bowled, 0) + v_team_a_overs,
        head_to_head = CASE 
          WHEN v_winner_id = v_team_b_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0)))
          WHEN v_loser_id = v_team_b_id THEN 
            jsonb_set(COALESCE(tournament_points_table.head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
              jsonb_build_object('won', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'won')::int, 0), 'lost', COALESCE((tournament_points_table.head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1))
          ELSE tournament_points_table.head_to_head
        END,
        updated_at = now();
      
      -- Update NRR for both teams
      UPDATE tournament_points_table SET
        net_run_rate = CASE 
          WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
            ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
          ELSE 0
        END
      WHERE tournament_id = v_tournament_id 
        AND team_id IN (v_team_a_id, v_team_b_id);
      
      -- Recalculate positions directly (no edge function call needed)
      PERFORM public.recalculate_tournament_positions(v_tournament_id);
    END IF;
    
    -- For API sync: use net.http_post with increased timeout
    -- This handles cases where match_result is NULL but API has data
    IF v_on_complete_sync THEN
      BEGIN
        PERFORM net.http_post(
          url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-points-table',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcXRlZm9ydW1qZHVnaWZ4cnlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NDY5NjQsImV4cCI6MjA4MjEyMjk2NH0.TzRAPhPWC6WN_IR24qEWA8TznqlrqPirJBdDmWyT9n8"}'::jsonb,
          body := jsonb_build_object('tournamentId', v_tournament_id),
          timeout_milliseconds := 30000
        );
        RAISE LOG 'Points table on-complete sync triggered for tournament % (match_result: %)', v_tournament_id, COALESCE(v_match_result, 'NULL');
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Failed to trigger on-complete sync for tournament %: %', v_tournament_id, SQLERRM;
      END;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260222230654_8d3501be-86f7-4089-9d27-5cf371280026.sql
-- ============================================


-- Drop the existing unique constraint on (tournament_id, team_id)
ALTER TABLE public.tournament_points_table DROP CONSTRAINT IF EXISTS tournament_points_table_tournament_id_team_id_key;

-- Add new unique constraint on (tournament_id, team_id, group_name)
CREATE UNIQUE INDEX tournament_points_table_tournament_team_group_key 
ON public.tournament_points_table (tournament_id, team_id, COALESCE(group_name, '__none__'));


-- ============================================
-- Source: 20260222230722_bb501a96-93d0-4ce8-8170-b9a582917eb5.sql
-- ============================================


ALTER TABLE public.tournament_points_table DROP CONSTRAINT tournament_points_table_tournament_team_unique;


-- ============================================
-- Source: 20260222231059_c02569f5-c0ba-4b84-96d7-d2e65c905f7d.sql
-- ============================================


CREATE OR REPLACE FUNCTION public.update_points_on_match_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tournament_id UUID;
  v_team_a_id UUID;
  v_team_b_id UUID;
  v_match_result TEXT;
  v_winner_id UUID;
  v_loser_id UUID;
  v_is_tied BOOLEAN := false;
  v_is_no_result BOOLEAN := false;
  v_is_draw BOOLEAN := false;
  v_team_a_runs INTEGER := 0;
  v_team_a_overs NUMERIC := 0;
  v_team_b_runs INTEGER := 0;
  v_team_b_overs NUMERIC := 0;
  v_innings_record RECORD;
  v_on_complete_sync BOOLEAN := false;
  v_has_valid_result BOOLEAN := false;
  v_group_name TEXT := NULL;
  v_existing_a_id UUID;
  v_existing_b_id UUID;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_tournament_id := NEW.tournament_id;
    v_team_a_id := NEW.team_a_id;
    v_team_b_id := NEW.team_b_id;
    v_match_result := NEW.match_result;
    
    IF v_tournament_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    SELECT points_table_on_complete_sync_enabled INTO v_on_complete_sync
    FROM tournaments WHERE id = v_tournament_id;
    
    -- Find the common group_name where BOTH teams exist in the points table
    -- This handles multiple stages (Group Stage, Super Eight, etc.)
    SELECT a.group_name INTO v_group_name
    FROM tournament_points_table a
    JOIN tournament_points_table b ON a.tournament_id = b.tournament_id AND a.group_name IS NOT DISTINCT FROM b.group_name
    WHERE a.tournament_id = v_tournament_id
      AND a.team_id = v_team_a_id
      AND b.team_id = v_team_b_id
    ORDER BY a.created_at DESC
    LIMIT 1;
    
    RAISE LOG 'update_points_on_match_complete: tournament=%, team_a=%, team_b=%, group=%', 
      v_tournament_id, v_team_a_id, v_team_b_id, COALESCE(v_group_name, 'NULL');
    
    CASE v_match_result
      WHEN 'team_a_won' THEN
        v_winner_id := v_team_a_id;
        v_loser_id := v_team_b_id;
        v_has_valid_result := true;
      WHEN 'team_b_won' THEN
        v_winner_id := v_team_b_id;
        v_loser_id := v_team_a_id;
        v_has_valid_result := true;
      WHEN 'tied' THEN
        v_is_tied := true;
        v_has_valid_result := true;
      WHEN 'no_result' THEN
        v_is_no_result := true;
        v_has_valid_result := true;
      WHEN 'draw' THEN
        v_is_draw := true;
        v_has_valid_result := true;
      ELSE
        v_has_valid_result := false;
    END CASE;
    
    IF v_has_valid_result THEN
      FOR v_innings_record IN 
        SELECT batting_team_id, COALESCE(runs, 0) as runs, COALESCE(overs, 0) as overs
        FROM match_innings 
        WHERE match_id = NEW.id
      LOOP
        IF v_innings_record.batting_team_id = v_team_a_id THEN
          v_team_a_runs := v_team_a_runs + v_innings_record.runs;
          v_team_a_overs := v_team_a_overs + v_innings_record.overs;
        ELSIF v_innings_record.batting_team_id = v_team_b_id THEN
          v_team_b_runs := v_team_b_runs + v_innings_record.runs;
          v_team_b_overs := v_team_b_overs + v_innings_record.overs;
        END IF;
      END LOOP;
      
      -- Team A: Check if entry exists for this group
      SELECT id INTO v_existing_a_id
      FROM tournament_points_table
      WHERE tournament_id = v_tournament_id AND team_id = v_team_a_id
        AND group_name IS NOT DISTINCT FROM v_group_name;
      
      IF v_existing_a_id IS NOT NULL THEN
        UPDATE tournament_points_table SET
          played = played + 1,
          won = won + CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
          lost = lost + CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
          tied = tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
          no_result = no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
          points = points + CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
          runs_scored = COALESCE(runs_scored, 0) + v_team_a_runs,
          overs_faced = COALESCE(overs_faced, 0) + v_team_a_overs,
          runs_conceded = COALESCE(runs_conceded, 0) + v_team_b_runs,
          overs_bowled = COALESCE(overs_bowled, 0) + v_team_b_overs,
          head_to_head = CASE 
            WHEN v_winner_id = v_team_a_id THEN 
              jsonb_set(COALESCE(head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
                jsonb_build_object('won', COALESCE((head_to_head->v_team_b_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((head_to_head->v_team_b_id::text->>'lost')::int, 0)))
            WHEN v_loser_id = v_team_a_id THEN 
              jsonb_set(COALESCE(head_to_head, '{}'::jsonb), ARRAY[v_team_b_id::text],
                jsonb_build_object('won', COALESCE((head_to_head->v_team_b_id::text->>'won')::int, 0), 'lost', COALESCE((head_to_head->v_team_b_id::text->>'lost')::int, 0) + 1))
            ELSE head_to_head
          END,
          updated_at = now()
        WHERE id = v_existing_a_id;
      ELSE
        INSERT INTO tournament_points_table (
          tournament_id, team_id, group_name, played, won, lost, tied, no_result, points, position,
          runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
        ) VALUES (
          v_tournament_id, v_team_a_id, v_group_name, 1,
          CASE WHEN v_winner_id = v_team_a_id THEN 1 ELSE 0 END,
          CASE WHEN v_loser_id = v_team_a_id THEN 1 ELSE 0 END,
          CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
          CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
          CASE WHEN v_winner_id = v_team_a_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
          0, v_team_a_runs, v_team_a_overs, v_team_b_runs, v_team_b_overs,
          CASE 
            WHEN v_winner_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 1, 'lost', 0))
            WHEN v_loser_id = v_team_a_id THEN jsonb_build_object(v_team_b_id::text, jsonb_build_object('won', 0, 'lost', 1))
            ELSE '{}'::jsonb
          END
        );
      END IF;
      
      -- Team B: Check if entry exists for this group
      SELECT id INTO v_existing_b_id
      FROM tournament_points_table
      WHERE tournament_id = v_tournament_id AND team_id = v_team_b_id
        AND group_name IS NOT DISTINCT FROM v_group_name;
      
      IF v_existing_b_id IS NOT NULL THEN
        UPDATE tournament_points_table SET
          played = played + 1,
          won = won + CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
          lost = lost + CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
          tied = tied + CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
          no_result = no_result + CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
          points = points + CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
          runs_scored = COALESCE(runs_scored, 0) + v_team_b_runs,
          overs_faced = COALESCE(overs_faced, 0) + v_team_b_overs,
          runs_conceded = COALESCE(runs_conceded, 0) + v_team_a_runs,
          overs_bowled = COALESCE(overs_bowled, 0) + v_team_a_overs,
          head_to_head = CASE 
            WHEN v_winner_id = v_team_b_id THEN 
              jsonb_set(COALESCE(head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
                jsonb_build_object('won', COALESCE((head_to_head->v_team_a_id::text->>'won')::int, 0) + 1, 'lost', COALESCE((head_to_head->v_team_a_id::text->>'lost')::int, 0)))
            WHEN v_loser_id = v_team_b_id THEN 
              jsonb_set(COALESCE(head_to_head, '{}'::jsonb), ARRAY[v_team_a_id::text],
                jsonb_build_object('won', COALESCE((head_to_head->v_team_a_id::text->>'won')::int, 0), 'lost', COALESCE((head_to_head->v_team_a_id::text->>'lost')::int, 0) + 1))
            ELSE head_to_head
          END,
          updated_at = now()
        WHERE id = v_existing_b_id;
      ELSE
        INSERT INTO tournament_points_table (
          tournament_id, team_id, group_name, played, won, lost, tied, no_result, points, position,
          runs_scored, overs_faced, runs_conceded, overs_bowled, head_to_head
        ) VALUES (
          v_tournament_id, v_team_b_id, v_group_name, 1,
          CASE WHEN v_winner_id = v_team_b_id THEN 1 ELSE 0 END,
          CASE WHEN v_loser_id = v_team_b_id THEN 1 ELSE 0 END,
          CASE WHEN v_is_tied OR v_is_draw THEN 1 ELSE 0 END,
          CASE WHEN v_is_no_result THEN 1 ELSE 0 END,
          CASE WHEN v_winner_id = v_team_b_id THEN 2 WHEN v_is_tied OR v_is_draw OR v_is_no_result THEN 1 ELSE 0 END,
          0, v_team_b_runs, v_team_b_overs, v_team_a_runs, v_team_a_overs,
          CASE 
            WHEN v_winner_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 1, 'lost', 0))
            WHEN v_loser_id = v_team_b_id THEN jsonb_build_object(v_team_a_id::text, jsonb_build_object('won', 0, 'lost', 1))
            ELSE '{}'::jsonb
          END
        );
      END IF;
      
      -- Update NRR for both teams in this group
      UPDATE tournament_points_table SET
        net_run_rate = CASE 
          WHEN COALESCE(overs_faced, 0) > 0 AND COALESCE(overs_bowled, 0) > 0 THEN
            ROUND(((COALESCE(runs_scored, 0)::numeric / NULLIF(overs_faced, 0)) - (COALESCE(runs_conceded, 0)::numeric / NULLIF(overs_bowled, 0)))::numeric, 3)
          ELSE 0
        END
      WHERE tournament_id = v_tournament_id 
        AND team_id IN (v_team_a_id, v_team_b_id)
        AND group_name IS NOT DISTINCT FROM v_group_name;
      
      PERFORM public.recalculate_tournament_positions(v_tournament_id);
    END IF;
    
    IF v_on_complete_sync THEN
      BEGIN
        PERFORM net.http_post(
          url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-points-table',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcXRlZm9ydW1qZHVnaWZ4cnlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NDY5NjQsImV4cCI6MjA4MjEyMjk2NH0.TzRAPhPWC6WN_IR24qEWA8TznqlrqPirJBdDmWyT9n8"}'::jsonb,
          body := jsonb_build_object('tournamentId', v_tournament_id),
          timeout_milliseconds := 30000
        );
        RAISE LOG 'Points table on-complete sync triggered for tournament % (match_result: %)', v_tournament_id, COALESCE(v_match_result, 'NULL');
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Failed to trigger on-complete sync for tournament %: %', v_tournament_id, SQLERRM;
      END;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260227180605_5a3989f6-d5b0-4e0b-9ed1-1f02782fe55b.sql
-- ============================================

-- Set match_result for completed matches based on scores
UPDATE matches
SET match_result = CASE
  WHEN COALESCE(NULLIF(regexp_replace(score_a, '[^0-9].*', ''), ''), '0')::int > 
       COALESCE(NULLIF(regexp_replace(score_b, '[^0-9].*', ''), ''), '0')::int 
    THEN 'team_a_won'
  WHEN COALESCE(NULLIF(regexp_replace(score_b, '[^0-9].*', ''), ''), '0')::int > 
       COALESCE(NULLIF(regexp_replace(score_a, '[^0-9].*', ''), ''), '0')::int 
    THEN 'team_b_won'
  WHEN COALESCE(NULLIF(regexp_replace(score_a, '[^0-9].*', ''), ''), '0')::int = 
       COALESCE(NULLIF(regexp_replace(score_b, '[^0-9].*', ''), ''), '0')::int 
    THEN 'tied'
  ELSE NULL
END
WHERE status = 'completed' 
  AND match_result IS NULL 
  AND score_a IS NOT NULL 
  AND score_b IS NOT NULL;

-- ============================================
-- Source: 20260227181057_a805c7a7-4731-4127-8812-a36aa19a3d95.sql
-- ============================================

ALTER TABLE site_settings ADD COLUMN IF NOT EXISTS auto_match_result_enabled boolean DEFAULT true;
ALTER TABLE site_settings_public ADD COLUMN IF NOT EXISTS auto_match_result_enabled boolean DEFAULT true;

-- Update the sync trigger to include the new column
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes, 
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes, 
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days, 
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled;

  RETURN NEW;
END;
$function$;

-- ============================================
-- Source: 20260227181240_c39e16ea-0322-4dbb-9ba3-d4af85c04a72.sql
-- ============================================

ALTER TABLE matches ADD COLUMN IF NOT EXISTS auto_match_result_enabled boolean DEFAULT true;

-- ============================================
-- Source: 20260308144019_b8608ff1-90e7-4749-a2cc-5212e66c5333.sql
-- ============================================


-- Add ad_click_protection JSON to site_settings
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS ad_click_protection jsonb DEFAULT '{"enabled": false, "max_clicks": 10, "time_window_days": 1, "block_duration_hours": 24}'::jsonb;

-- Add ad_click_protection to site_settings_public  
ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS ad_click_protection jsonb DEFAULT '{"enabled": false, "max_clicks": 10, "time_window_days": 1, "block_duration_hours": 24}'::jsonb;

-- Create ad_click_logs table for tracking clicks per device
CREATE TABLE public.ad_click_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_fingerprint text NOT NULL,
  click_count integer NOT NULL DEFAULT 1,
  first_click_at timestamp with time zone NOT NULL DEFAULT now(),
  last_click_at timestamp with time zone NOT NULL DEFAULT now(),
  blocked_until timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create index for fast lookups
CREATE INDEX idx_ad_click_logs_fingerprint ON public.ad_click_logs(device_fingerprint);
CREATE INDEX idx_ad_click_logs_blocked ON public.ad_click_logs(blocked_until) WHERE blocked_until IS NOT NULL;

-- Enable RLS
ALTER TABLE public.ad_click_logs ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read (to check if blocked)
CREATE POLICY "Anyone can read ad click logs" ON public.ad_click_logs FOR SELECT USING (true);

-- Allow anyone to insert/update (anonymous visitors need to log clicks)
CREATE POLICY "Anyone can insert ad click logs" ON public.ad_click_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update ad click logs" ON public.ad_click_logs FOR UPDATE USING (true);

-- Admins can delete
CREATE POLICY "Admins can delete ad click logs" ON public.ad_click_logs FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Update the sync trigger to include ad_click_protection
CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes, 
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled, ad_click_protection
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes, 
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled, NEW.ad_click_protection
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days, 
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled,
    ad_click_protection = EXCLUDED.ad_click_protection;

  RETURN NEW;
END;
$function$;


-- ============================================
-- Source: 20260316041625_5df30c99-f5c0-485a-86cc-f7b8a4f9ba81.sql
-- ============================================


CREATE TABLE public.tournament_venues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  venue_name TEXT NOT NULL,
  city TEXT,
  country TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.tournament_venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tournament venues are viewable by everyone"
  ON public.tournament_venues FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage tournament venues"
  ON public.tournament_venues FOR ALL
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));


-- ============================================
-- Source: 20260406063341_2338cfcd-8278-4405-899a-3772ef725e25.sql
-- ============================================

ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS playing_xi_auto_sync_source TEXT DEFAULT 'api_cricket';

-- ============================================
-- Source: 20260407021140_3d6d4328-a347-42a3-9eba-5091a0ebd1d6.sql
-- ============================================

ALTER TABLE public.site_settings
ADD COLUMN IF NOT EXISTS playing_xi_auto_sync_source text NOT NULL DEFAULT 'api_cricket';

ALTER TABLE public.site_settings
DROP CONSTRAINT IF EXISTS site_settings_playing_xi_auto_sync_source_check;

ALTER TABLE public.site_settings
ADD CONSTRAINT site_settings_playing_xi_auto_sync_source_check
CHECK (playing_xi_auto_sync_source IN ('api_cricket', 'espn'));

ALTER TABLE public.site_settings_public
ADD COLUMN IF NOT EXISTS playing_xi_auto_sync_source text NOT NULL DEFAULT 'api_cricket';

ALTER TABLE public.site_settings_public
DROP CONSTRAINT IF EXISTS site_settings_public_playing_xi_auto_sync_source_check;

ALTER TABLE public.site_settings_public
ADD CONSTRAINT site_settings_public_playing_xi_auto_sync_source_check
CHECK (playing_xi_auto_sync_source IN ('api_cricket', 'espn'));

CREATE OR REPLACE FUNCTION public.sync_site_settings_public_from_site_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes,
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled, ad_click_protection,
    playing_xi_auto_sync_source
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes,
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled, NEW.ad_click_protection,
    NEW.playing_xi_auto_sync_source
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled,
    ad_click_protection = EXCLUDED.ad_click_protection,
    playing_xi_auto_sync_source = EXCLUDED.playing_xi_auto_sync_source;

  RETURN NEW;
END;
$function$;

UPDATE public.site_settings
SET playing_xi_auto_sync_source = COALESCE(playing_xi_auto_sync_source, 'api_cricket')
WHERE playing_xi_auto_sync_source IS NULL;

UPDATE public.site_settings_public p
SET playing_xi_auto_sync_source = COALESCE(s.playing_xi_auto_sync_source, 'api_cricket')
FROM public.site_settings s
WHERE p.id = s.id;

-- ============================================
-- Source: 20260501174847_8d88cf3e-febe-4381-91ad-acba93c19e05.sql
-- ============================================


ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS sofascore_event_id TEXT;
ALTER TABLE public.match_playing_xi ADD COLUMN IF NOT EXISTS sofascore_player_id TEXT;


-- ============================================
-- Source: 20260501180154_b1eaa698-39d6-438e-82cd-069a6d8dfd18.sql
-- ============================================

ALTER TABLE public.site_settings DROP CONSTRAINT IF EXISTS site_settings_playing_xi_auto_sync_source_check;
ALTER TABLE public.site_settings ADD CONSTRAINT site_settings_playing_xi_auto_sync_source_check CHECK (playing_xi_auto_sync_source = ANY (ARRAY['api_cricket'::text, 'espn'::text, 'sofascore'::text]));

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='site_settings_public' AND column_name='playing_xi_auto_sync_source') THEN
    EXECUTE 'ALTER TABLE public.site_settings_public DROP CONSTRAINT IF EXISTS site_settings_public_playing_xi_auto_sync_source_check';
    EXECUTE 'ALTER TABLE public.site_settings_public ADD CONSTRAINT site_settings_public_playing_xi_auto_sync_source_check CHECK (playing_xi_auto_sync_source = ANY (ARRAY[''api_cricket''::text, ''espn''::text, ''sofascore''::text]))';
  END IF;
END $$;

-- ============================================
-- Source: 20260502112201_c5166917-a381-4a5d-ab10-9d9c483259bc.sql
-- ============================================


ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS crex_match_fkey text;

-- Allow 'crex' as a valid playing_xi_auto_sync_source value
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT conname, conrelid::regclass::text AS tbl
    FROM pg_constraint
    WHERE conname LIKE '%playing_xi_auto_sync_source%'
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tbl, r.conname);
  END LOOP;
END $$;

ALTER TABLE public.site_settings
  ADD CONSTRAINT site_settings_playing_xi_auto_sync_source_check
  CHECK (playing_xi_auto_sync_source IN ('api_cricket','espn','sofascore','crex'));

ALTER TABLE public.site_settings_public
  ADD CONSTRAINT site_settings_public_playing_xi_auto_sync_source_check
  CHECK (playing_xi_auto_sync_source IN ('api_cricket','espn','sofascore','crex'));


-- ============================================
-- Source: 20260504024312_88ee2df3-f8ca-449c-b82c-35713d89d5d3.sql
-- ============================================


-- 1. JSON sources table
CREATE TABLE IF NOT EXISTS public.streaming_json_sources (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  last_sync_status TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.streaming_json_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active json sources viewable by everyone"
  ON public.streaming_json_sources FOR SELECT
  USING (true);

CREATE POLICY "Admins manage json sources"
  ON public.streaming_json_sources FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_json_sources_updated
  BEFORE UPDATE ON public.streaming_json_sources
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 2. Per-match toggle
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS auto_streaming_enabled BOOLEAN NOT NULL DEFAULT true;

-- 3. Streaming server origin tracking
ALTER TABLE public.streaming_servers
  ADD COLUMN IF NOT EXISTS auto_source_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS streaming_servers_auto_source_unique
  ON public.streaming_servers (match_id, auto_source_id)
  WHERE auto_source_id IS NOT NULL;

-- 4. Cron job — every 5 minutes
CREATE OR REPLACE FUNCTION public.call_sync_streaming_from_json()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://doqteforumjdugifxryl.supabase.co/functions/v1/sync-streaming-from-json',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'sync-streaming-from-json error: %', SQLERRM;
END;
$$;

DO $$ BEGIN
  PERFORM cron.unschedule('sync-streaming-from-json-every-5m');
EXCEPTION WHEN OTHERS THEN NULL; END $$;

SELECT cron.schedule(
  'sync-streaming-from-json-every-5m',
  '*/5 * * * *',
  $$SELECT public.call_sync_streaming_from_json()$$
);


-- ============================================
-- Source: 20260505033123_3d425afb-9764-463b-b011-7a3d27755c30.sql
-- ============================================


ALTER TABLE public.streaming_json_sources
  ADD COLUMN IF NOT EXISTS url_field text NOT NULL DEFAULT 'playerUrl',
  ADD COLUMN IF NOT EXISTS display_order integer NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_streaming_json_sources_order
  ON public.streaming_json_sources (display_order, created_at);


-- ============================================
-- Source: 20260506020704_fix_saudi_league_code.sql
-- ============================================

UPDATE football_leagues SET league_code='ksa.1', updated_at=now() WHERE league_code='sau.1';


-- ============================================
-- Source: 20260608185639_a67c249c-1acd-44c6-a350-fbc9b73f7354.sql
-- ============================================

ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS manual_scoreboard_enabled BOOLEAN NOT NULL DEFAULT false;

-- ============================================
-- Source: 20260613140751_8d081f87-b702-46e3-89f8-1b1ad7ea3a2b.sql
-- ============================================

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS aliases TEXT[] NOT NULL DEFAULT '{}'::text[];

-- ============================================
-- Source: 20260615021021_5061356a-b5a1-4d4d-aeb9-01a803c49865.sql
-- ============================================

ALTER TABLE public.streaming_json_sources
ADD COLUMN IF NOT EXISTS use_entry_name boolean NOT NULL DEFAULT false;

-- ============================================
-- Source: 20260616054923_8af9bca1-9f75-4590-ba40-06bffad5d418.sql
-- ============================================

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS head_coach_a TEXT,
  ADD COLUMN IF NOT EXISTS head_coach_b TEXT;

-- ============================================
-- Source: 20260702065800_647173b0-fa8f-4245-a060-226e7ae55fc8.sql
-- ============================================


ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS player_load_time_seconds integer NOT NULL DEFAULT 0;
ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS player_load_time_seconds integer NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.sync_site_settings_public()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes,
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled, ad_click_protection,
    player_load_time_seconds
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes,
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled, NEW.ad_click_protection,
    NEW.player_load_time_seconds
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled,
    ad_click_protection = EXCLUDED.ad_click_protection,
    player_load_time_seconds = EXCLUDED.player_load_time_seconds;
  RETURN NEW;
END;
$function$;

-- Sync existing row
UPDATE public.site_settings SET updated_at = now();


-- ============================================
-- Source: 20260702072353_c5efa365-9e6b-4a49-b16e-98b01e57e55f.sql
-- ============================================

ALTER TABLE public.streaming_servers ADD COLUMN IF NOT EXISTS name_locked BOOLEAN NOT NULL DEFAULT false;

-- ============================================
-- Source: 20260702073133_9ad01003-d6bf-41bc-be8c-a43f059e202e.sql
-- ============================================

ALTER TABLE public.match_playing_xi 
  ADD COLUMN IF NOT EXISTS jersey_number INTEGER,
  ADD COLUMN IF NOT EXISTS formation TEXT,
  ADD COLUMN IF NOT EXISTS formation_place INTEGER;

-- ============================================
-- Source: 20260702080332_b7d4cf14-2516-4aeb-a5db-199a1c8d54d8.sql
-- ============================================


-- Bottom navigation items
CREATE TABLE public.bottom_nav_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  label TEXT NOT NULL,
  url TEXT NOT NULL,
  icon_name TEXT NOT NULL DEFAULT 'Home',
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON public.bottom_nav_items TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bottom_nav_items TO authenticated;
GRANT ALL ON public.bottom_nav_items TO service_role;

ALTER TABLE public.bottom_nav_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Bottom nav readable by all"
ON public.bottom_nav_items FOR SELECT
USING (true);

CREATE POLICY "Admins manage bottom nav"
ON public.bottom_nav_items FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'admin'))
WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER trg_bottom_nav_items_updated
BEFORE UPDATE ON public.bottom_nav_items
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

INSERT INTO public.bottom_nav_items (label, url, icon_name, display_order) VALUES
('Home', '/', 'Tv', 1),
('Live', '/?filter=live', 'Radio', 2),
('Channels', '/channels', 'LayoutGrid', 3),
('Tournament', '/?section=tournaments', 'Trophy', 4);

-- Auto-complete expired tournaments
CREATE OR REPLACE FUNCTION public.auto_complete_expired_tournaments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.tournaments
  SET is_completed = true,
      updated_at = now()
  WHERE end_date IS NOT NULL
    AND end_date < CURRENT_DATE
    AND (is_completed IS NULL OR is_completed = false);
END;
$$;

-- Schedule daily at 00:05 UTC via pg_cron if available
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('auto-complete-expired-tournaments')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-complete-expired-tournaments');
    PERFORM cron.schedule(
      'auto-complete-expired-tournaments',
      '5 0 * * *',
      $cron$ SELECT public.auto_complete_expired_tournaments(); $cron$
    );
  END IF;
END $$;

-- Run once immediately to backfill
SELECT public.auto_complete_expired_tournaments();


-- ============================================
-- Source: 20260702090029_dcd8416c-aba6-4d66-bc6a-c0ba5735a0af.sql
-- ============================================

UPDATE public.bottom_nav_items SET url='/tournaments', updated_at=now() WHERE url='/?section=tournaments';

-- ============================================
-- Source: 20260702091036_c8c2fb59-53ae-4e26-b891-c68baeebe737.sql
-- ============================================


ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS default_iframe_url TEXT;
ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS default_iframe_url TEXT;

CREATE OR REPLACE FUNCTION public.sync_site_settings_public()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes,
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled, ad_click_protection,
    player_load_time_seconds, default_iframe_url
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes,
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled, NEW.ad_click_protection,
    NEW.player_load_time_seconds, NEW.default_iframe_url
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled,
    ad_click_protection = EXCLUDED.ad_click_protection,
    player_load_time_seconds = EXCLUDED.player_load_time_seconds,
    default_iframe_url = EXCLUDED.default_iframe_url;
  RETURN NEW;
END;
$function$;

-- Sync current row so public table has latest value
UPDATE public.site_settings SET updated_at = now();


-- ============================================
-- Source: 20260702091343_0feec45e-c9f0-410c-989e-70f0533c177c.sql
-- ============================================


ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS default_iframe_enabled BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.site_settings_public ADD COLUMN IF NOT EXISTS default_iframe_enabled BOOLEAN NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.sync_site_settings_public()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.site_settings_public (
    id, site_name, site_title, site_description, site_keywords,
    logo_url, favicon_url, og_image_url, footer_text, google_analytics_id,
    created_at, updated_at, header_ad_code, sidebar_ad_code, footer_ad_code,
    in_article_ad_code, popup_ad_code, ads_enabled, google_adsense_id,
    canonical_url, robots_txt, schema_org_enabled, twitter_handle, facebook_app_id,
    telegram_link, social_links, cricket_api_enabled, ads_txt_content,
    custom_header_code, custom_footer_code, match_page_ad_positions,
    api_cricket_enabled, api_sync_interval_seconds, slider_duration_seconds,
    admin_slug, rapidapi_endpoints, maintenance_mode, maintenance_title,
    maintenance_subtitle, maintenance_description, maintenance_estimated_time,
    maintenance_show_countdown, maintenance_end_time, maintenance_contact_email,
    maintenance_social_message, disclaimer_text, show_disclaimer,
    homepage_completed_days, homepage_channels_limit, multiple_ad_codes,
    tournament_page_ad_positions, points_table_sync_time, points_table_auto_sync_enabled,
    ad_block_rules, rapidapi_enabled, auto_match_result_enabled, ad_click_protection,
    player_load_time_seconds, default_iframe_url, default_iframe_enabled
  ) VALUES (
    NEW.id, NEW.site_name, NEW.site_title, NEW.site_description, NEW.site_keywords,
    NEW.logo_url, NEW.favicon_url, NEW.og_image_url, NEW.footer_text, NEW.google_analytics_id,
    NEW.created_at, NEW.updated_at, NEW.header_ad_code, NEW.sidebar_ad_code, NEW.footer_ad_code,
    NEW.in_article_ad_code, NEW.popup_ad_code, NEW.ads_enabled, NEW.google_adsense_id,
    NEW.canonical_url, NEW.robots_txt, NEW.schema_org_enabled, NEW.twitter_handle, NEW.facebook_app_id,
    NEW.telegram_link, NEW.social_links, NEW.cricket_api_enabled, NEW.ads_txt_content,
    NEW.custom_header_code, NEW.custom_footer_code, NEW.match_page_ad_positions,
    NEW.api_cricket_enabled, NEW.api_sync_interval_seconds, NEW.slider_duration_seconds,
    NEW.admin_slug, NEW.rapidapi_endpoints, NEW.maintenance_mode, NEW.maintenance_title,
    NEW.maintenance_subtitle, NEW.maintenance_description, NEW.maintenance_estimated_time,
    NEW.maintenance_show_countdown, NEW.maintenance_end_time, NEW.maintenance_contact_email,
    NEW.maintenance_social_message, NEW.disclaimer_text, NEW.show_disclaimer,
    NEW.homepage_completed_days, NEW.homepage_channels_limit, NEW.multiple_ad_codes,
    NEW.tournament_page_ad_positions, NEW.points_table_sync_time, NEW.points_table_auto_sync_enabled,
    NEW.ad_block_rules, NEW.rapidapi_enabled, NEW.auto_match_result_enabled, NEW.ad_click_protection,
    NEW.player_load_time_seconds, NEW.default_iframe_url, NEW.default_iframe_enabled
  )
  ON CONFLICT (id) DO UPDATE SET
    site_name = EXCLUDED.site_name, site_title = EXCLUDED.site_title,
    site_description = EXCLUDED.site_description, site_keywords = EXCLUDED.site_keywords,
    logo_url = EXCLUDED.logo_url, favicon_url = EXCLUDED.favicon_url,
    og_image_url = EXCLUDED.og_image_url, footer_text = EXCLUDED.footer_text,
    google_analytics_id = EXCLUDED.google_analytics_id, created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at, header_ad_code = EXCLUDED.header_ad_code,
    sidebar_ad_code = EXCLUDED.sidebar_ad_code, footer_ad_code = EXCLUDED.footer_ad_code,
    in_article_ad_code = EXCLUDED.in_article_ad_code, popup_ad_code = EXCLUDED.popup_ad_code,
    ads_enabled = EXCLUDED.ads_enabled, google_adsense_id = EXCLUDED.google_adsense_id,
    canonical_url = EXCLUDED.canonical_url, robots_txt = EXCLUDED.robots_txt,
    schema_org_enabled = EXCLUDED.schema_org_enabled, twitter_handle = EXCLUDED.twitter_handle,
    facebook_app_id = EXCLUDED.facebook_app_id, telegram_link = EXCLUDED.telegram_link,
    social_links = EXCLUDED.social_links, cricket_api_enabled = EXCLUDED.cricket_api_enabled,
    ads_txt_content = EXCLUDED.ads_txt_content, custom_header_code = EXCLUDED.custom_header_code,
    custom_footer_code = EXCLUDED.custom_footer_code, match_page_ad_positions = EXCLUDED.match_page_ad_positions,
    api_cricket_enabled = EXCLUDED.api_cricket_enabled, api_sync_interval_seconds = EXCLUDED.api_sync_interval_seconds,
    slider_duration_seconds = EXCLUDED.slider_duration_seconds, admin_slug = EXCLUDED.admin_slug,
    rapidapi_endpoints = EXCLUDED.rapidapi_endpoints, maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_title = EXCLUDED.maintenance_title, maintenance_subtitle = EXCLUDED.maintenance_subtitle,
    maintenance_description = EXCLUDED.maintenance_description, maintenance_estimated_time = EXCLUDED.maintenance_estimated_time,
    maintenance_show_countdown = EXCLUDED.maintenance_show_countdown, maintenance_end_time = EXCLUDED.maintenance_end_time,
    maintenance_contact_email = EXCLUDED.maintenance_contact_email, maintenance_social_message = EXCLUDED.maintenance_social_message,
    disclaimer_text = EXCLUDED.disclaimer_text, show_disclaimer = EXCLUDED.show_disclaimer,
    homepage_completed_days = EXCLUDED.homepage_completed_days,
    homepage_channels_limit = EXCLUDED.homepage_channels_limit,
    multiple_ad_codes = EXCLUDED.multiple_ad_codes,
    tournament_page_ad_positions = EXCLUDED.tournament_page_ad_positions,
    points_table_sync_time = EXCLUDED.points_table_sync_time,
    points_table_auto_sync_enabled = EXCLUDED.points_table_auto_sync_enabled,
    ad_block_rules = EXCLUDED.ad_block_rules,
    rapidapi_enabled = EXCLUDED.rapidapi_enabled,
    auto_match_result_enabled = EXCLUDED.auto_match_result_enabled,
    ad_click_protection = EXCLUDED.ad_click_protection,
    player_load_time_seconds = EXCLUDED.player_load_time_seconds,
    default_iframe_url = EXCLUDED.default_iframe_url,
    default_iframe_enabled = EXCLUDED.default_iframe_enabled;
  RETURN NEW;
END;
$function$;

UPDATE public.site_settings SET updated_at = now();


-- ============================================
-- Source: 20260702100238_7301ee55-066e-4d29-9055-766fc2c26095.sql
-- ============================================


-- Events table for non-team events (opening ceremony, auction, etc.)
CREATE TABLE public.events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  logo_url TEXT,
  location TEXT,
  year INTEGER,
  description TEXT,
  event_start_time TIMESTAMPTZ NOT NULL,
  event_end_time TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'upcoming',
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_priority BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON public.events TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT ALL ON public.events TO service_role;

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active events" ON public.events
  FOR SELECT USING (is_active = true OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can insert events" ON public.events
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update events" ON public.events
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete events" ON public.events
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE INDEX idx_events_start_time ON public.events(event_start_time);
CREATE INDEX idx_events_slug ON public.events(slug);

-- Streaming servers for events (parallel to matches' streaming_servers)
CREATE TABLE public.event_streaming_servers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  server_name TEXT NOT NULL,
  server_url TEXT NOT NULL,
  server_type TEXT NOT NULL DEFAULT 'iframe',
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  referer_value TEXT,
  origin_value TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON public.event_streaming_servers TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_streaming_servers TO authenticated;
GRANT ALL ON public.event_streaming_servers TO service_role;

ALTER TABLE public.event_streaming_servers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active event servers" ON public.event_streaming_servers
  FOR SELECT USING (is_active = true OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage event servers" ON public.event_streaming_servers
  FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER update_event_streaming_servers_updated_at BEFORE UPDATE ON public.event_streaming_servers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE INDEX idx_event_streaming_servers_event_id ON public.event_streaming_servers(event_id);

