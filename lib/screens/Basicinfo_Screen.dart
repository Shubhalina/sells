import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameController = TextEditingController(
      text: user?.userMetadata?['full_name'] ?? 'Shubhaiina Radu Kakaty',
    );
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Information'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLength: 30,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about yourself',
                  border: OutlineInputBorder(),
                  counterText: '${_descriptionController.text.length}/30',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Divider(height: 40),
              Text(
                'Contact information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter your phone',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This is the number for buyers contacts, reminders, and other notifications.',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: user?.email ?? 'shubhaiinaradukakaty@gmail.com',
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your email is never shared with external parties nor do we use it to spam you in any way.',
                style: TextStyle(color: Colors.grey),
              ),
              Divider(height: 40),
              Text(
                'Additional information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.account_circle, size: 40),
                title: Text('Google'),
                subtitle: Text('Link your Google account'),
                trailing: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Unlink',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save the changes
                    Navigator.pop(context);
                  }
                },
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}