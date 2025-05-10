// edit_internship_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditInternshipScreen extends StatefulWidget {
  final Map<String, dynamic> internshipData;
  final Function onUpdate;
  final String internshipId;

  const EditInternshipScreen({
    Key? key,
    required this.internshipData,
    required this.onUpdate,
    required this.internshipId,
  }) : super(key: key);

  @override
  _EditInternshipScreenState createState() => _EditInternshipScreenState();
}

class _EditInternshipScreenState extends State<EditInternshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for all the fields
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _durationController;
  late TextEditingController _responsibilitiesController;
  late TextEditingController _requirementsController;
  late TextEditingController _qualificationsController;
  late TextEditingController _typeController;
  late TextEditingController _internshipTypeController;

  Map<String, dynamic> _currentInternshipData = {};
  bool _isLoading = false;
  String _originalCompanyName = "";

  @override
  void initState() {
    super.initState();

    // Initialize with data passed from parent, then fetch latest
    _currentInternshipData = Map<String, dynamic>.from(widget.internshipData);

    // Controllers initialized with empty values initially
    _companyController = TextEditingController();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _durationController = TextEditingController();
    _responsibilitiesController = TextEditingController();
    _requirementsController = TextEditingController();
    _qualificationsController = TextEditingController();
    _typeController = TextEditingController();
    _internshipTypeController = TextEditingController();

    // Load latest data from Firestore
    _fetchLatestInternshipData();
  }

  Future<void> _fetchLatestInternshipData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the latest data directly from Firestore
      final internshipDoc = await _firestore
          .collection('interns')
          .doc(_currentInternshipData["id"])
          .get();

      if (internshipDoc.exists) {
        setState(() {
          // Update with latest data from Firestore
          _currentInternshipData = {
            ...internshipDoc.data()!,
            'id': internshipDoc.id,
          };
        });

        print("Fetched latest data: $_currentInternshipData");

        // Now update all controllers with the latest data
        _updateControllersWithLatestData();
      }
    } catch (e) {
      print("Error fetching latest internship data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateControllersWithLatestData() {
    // Update all controllers with latest data
    _titleController.text = _currentInternshipData["title"] ?? "";
    _locationController.text = _currentInternshipData["location"] ?? "";
    _durationController.text = _currentInternshipData["duration"] ?? "";
    _responsibilitiesController.text = _currentInternshipData["whatYouWillBeDoing"] ?? "";
    _requirementsController.text = _currentInternshipData["whatWeAreLookingFor"] ?? "";
    _qualificationsController.text = _currentInternshipData["preferredQualifications"] ?? "";
    _typeController.text = _currentInternshipData["type"] ?? "";
    _internshipTypeController.text = _currentInternshipData["internship"] ?? "";

    // Load company name last (might be async)
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    try {
      // Print debug info about the current data
      print("Loading company data. Current company: ${_currentInternshipData["company"]}, companyId: ${_currentInternshipData["companyId"]}");

      // First try to use the company field directly from the latest data
      if (_currentInternshipData["company"] != null &&
          _currentInternshipData["company"].toString().isNotEmpty) {
        setState(() {
          _companyController.text = _currentInternshipData["company"];
          _originalCompanyName = _currentInternshipData["company"];
        });
        print("Using company name from latest data: ${_companyController.text}");
        return;
      }

      // If no company name is available, try to get it from the company ID
      if (_currentInternshipData["companyId"] != null &&
          _currentInternshipData["companyId"].toString().isNotEmpty) {
        final companyId = _currentInternshipData["companyId"];
        final doc = await _firestore.collection("company").doc(companyId).get();

        if (doc.exists && doc.data()?["CompanyName"] != null) {
          setState(() {
            _companyController.text = doc.data()?["companyName"] ?? "";
            _originalCompanyName = _companyController.text;
          });
          print("Using company name from Firestore: ${_companyController.text}");
        }
      }
    } catch (e) {
      print("Failed to load company name: $e");
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _companyController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _responsibilitiesController.dispose();
    _requirementsController.dispose();
    _qualificationsController.dispose();
    _typeController.dispose();
    _internshipTypeController.dispose();
    super.dispose();
  }

  Future<void> _updateInternship() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String companyId = _currentInternshipData["companyId"] ?? "";
        String companyName = _companyController.text.trim();

        // Check if company name has changed
        if (companyName != _originalCompanyName && companyId.isNotEmpty) {
          // Update the companyName in the original 'company' collection
          await _firestore.collection('company').doc(companyId).update({
            'companyName': companyName,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print("Company name updated in 'company' collection.");
        }

        Map<String, dynamic> updateData = {
          'company': companyName,
          'companyId': companyId,
          'title': _titleController.text.trim(),
          'location': _locationController.text.trim(),
          'duration': _durationController.text.trim(),
          'whatYouWillBeDoing': _responsibilitiesController.text.trim(),
          'whatWeAreLookingFor': _requirementsController.text.trim(),
          'preferredQualifications': _qualificationsController.text.trim(),
          'type': _typeController.text.trim(),
          'internship': _internshipTypeController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update the 'interns' document
        await _firestore.collection('interns').doc(_currentInternshipData["id"]).update(updateData);
// If the companyId is valid and the name was changed, update CompanyName in the company document
        if (companyId.isNotEmpty && companyName != _originalCompanyName) {
          await _firestore.collection('company').doc(companyId).update({
            'CompanyName': companyName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print("Updated CompanyName in company table.");
        }

        print("Internship updated successfully.");

        setState(() {
          _currentInternshipData = {
            ..._currentInternshipData,
            ...updateData,
          };
        });

        widget.onUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Internship updated successfully", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print("Error updating internship: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating internship: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2252A1)),
        title: Text(
          "Edit Internship",
          style: TextStyle(color: Color(0xFF2252A1), fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Company Information"),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _companyController,
                  label: "Company Name",
                  validator: _requiredValidator,
                ),
                SizedBox(height: 16),

                _buildSectionTitle("Internship Details"),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  label: "Internship Title",
                  validator: _requiredValidator,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _locationController,
                  label: "Location",
                  validator: _requiredValidator,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _durationController,
                  label: "Duration",
                  validator: _requiredValidator,
                  hint: "e.g., 3 months, Summer 2025",
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _typeController,
                        label: "Type",
                        validator: _requiredValidator,
                        hint: "e.g., Full-time, Part-time",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _internshipTypeController,
                        label: "Internship Type",
                        validator: _requiredValidator,
                        hint: "e.g., Paid, Unpaid",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                _buildSectionTitle("Job Description"),
                SizedBox(height: 12),
                _buildTextArea(
                  controller: _responsibilitiesController,
                  label: "What You Will Be Doing",
                  validator: _requiredValidator,
                  hint: "List the responsibilities and tasks",
                  maxLines: 5,
                ),
                SizedBox(height: 12),
                _buildTextArea(
                  controller: _requirementsController,
                  label: "What We Are Looking For",
                  validator: _requiredValidator,
                  hint: "List the key requirements",
                  maxLines: 5,
                ),
                SizedBox(height: 12),
                _buildTextArea(
                  controller: _qualificationsController,
                  label: "Preferred Qualifications",
                  validator: _requiredValidator,
                  hint: "List preferred skills and qualifications",
                  maxLines: 5,
                ),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _updateInternship,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2252A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Update Internship",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2252A1),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hint,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      maxLines: maxLines,
      textAlignVertical: TextAlignVertical.top,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}