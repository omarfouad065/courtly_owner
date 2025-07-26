# Supabase Setup Guide for Courtly Owner App

This guide will help you set up Supabase for image uploads in your Flutter app.

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. Flutter project with the required dependencies

## Step 1: Create a Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: `courtly-owner` (or your preferred name)
   - Database Password: Create a strong password
   - Region: Choose the closest region to your users
5. Click "Create new project"

## Step 2: Get Your Project Credentials

1. In your Supabase dashboard, go to Settings → API
2. Copy the following values:
   - **Project URL** (starts with `https://`)
   - **anon public** key (starts with `eyJ`)

## Step 3: Configure Your Flutter App

1. Open `lib/core/config/supabase_config.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_ACTUAL_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY';
  
  static const String courtImagesBucket = 'court-images';
}
```

## Step 4: Set Up Storage Bucket

1. In your Supabase dashboard, go to Storage
2. Click "Create a new bucket"
3. Enter bucket name: `court-images`
4. Make sure "Public bucket" is checked
5. Click "Create bucket"

## Step 5: Configure Storage Policies

1. In the Storage section, click on your `court-images` bucket
2. Go to "Policies" tab
3. Click "New Policy"
4. Choose "Create a policy from scratch"
5. Configure the policy:

### For INSERT (Upload) Policy:
- Policy Name: `Allow authenticated uploads`
- Allowed operation: `INSERT`
- Target roles: `authenticated`
- Policy definition:
```sql
(auth.role() = 'authenticated')
```

### For SELECT (Download) Policy:
- Policy Name: `Allow public downloads`
- Allowed operation: `SELECT`
- Target roles: `anon, authenticated`
- Policy definition:
```sql
(true)
```

### For DELETE Policy:
- Policy Name: `Allow authenticated deletes`
- Allowed operation: `DELETE`
- Target roles: `authenticated`
- Policy definition:
```sql
(auth.role() = 'authenticated')
```

## Step 6: Install Dependencies

Run the following command to install the required packages:

```bash
flutter pub get
```

## Step 7: Test the Integration

1. Run your Flutter app
2. Go to the "Add Court" screen
3. Try uploading images using the image picker
4. Check that images are uploaded to Supabase Storage

## Troubleshooting

### Common Issues:

1. **"Bucket not found" error**
   - Make sure you created the `court-images` bucket in Supabase
   - Check that the bucket name matches exactly

2. **"Permission denied" error**
   - Verify that your storage policies are correctly configured
   - Make sure the bucket is public

3. **"Invalid credentials" error**
   - Double-check your Supabase URL and anon key
   - Make sure there are no extra spaces or characters

4. **Images not uploading**
   - Check your internet connection
   - Verify that the Supabase service is properly initialized in `main.dart`

### Debug Tips:

1. Check the console logs for detailed error messages
2. Verify your Supabase project is active and not paused
3. Test with smaller image files first
4. Check the Supabase dashboard Storage section to see uploaded files

## Security Considerations

1. **Public Access**: The current setup allows public read access to images. For production, consider implementing more restrictive policies.

2. **File Size Limits**: Consider implementing file size limits in your app to prevent abuse.

3. **File Type Validation**: Add validation to ensure only image files are uploaded.

4. **Authentication**: Consider requiring user authentication before allowing uploads.

## Next Steps

1. Implement image compression before upload
2. Add image preview functionality
3. Implement image deletion when courts are removed
4. Add image optimization and CDN integration
5. Implement user-specific storage quotas

## Support

If you encounter issues:
1. Check the Supabase documentation: https://supabase.com/docs
2. Review the Flutter Supabase package documentation
3. Check the Supabase community forums 