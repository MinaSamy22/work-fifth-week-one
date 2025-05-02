import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

class CourseUploadPage extends StatefulWidget {
  const CourseUploadPage({Key? key}) : super(key: key);

  @override
  _CourseUploadPageState createState() => _CourseUploadPageState();
}

class _CourseUploadPageState extends State<CourseUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyLinkController = TextEditingController();

  XFile? _courseImage;
  XFile? _companyLogo;
  List<XFile> _roadmapImages = [];
  XFile? _videoFile;

  String _companyType = 'online';

  List<Map<String, dynamic>> _companies = [];

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseDescriptionController.dispose();
    _companyNameController.dispose();
    _companyLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _courseImage = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _courseImage = pickedFile;
        });
      }
    }
  }

  Future<void> _pickCompanyLogo() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _companyLogo = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _companyLogo = pickedFile;
        });
      }
    }
  }

  Future<void> _pickRoadmapImages() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _roadmapImages = result.files.map((file) => XFile(file.path!)).toList();
        });
      }
    } else {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _roadmapImages = pickedFiles;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _videoFile = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoFile = pickedFile;
        });
      }
    }
  }

  Future<String> _uploadFile(XFile file, String bucketName) async {
    final fileExtension = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final fileBytes = await file.readAsBytes();

    await _supabase.storage.from(bucketName).uploadBinary(fileName, fileBytes);

    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  void _addCompany() {
    if (_companyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name is required')),
      );
      return;
    }

    setState(() {
      _companies.add({
        'name': _companyNameController.text,
        'link': _companyLinkController.text,
        'logo': _companyLogo,
        'type': _companyType,
      });

      // Clear fields
      _companyNameController.clear();
      _companyLinkController.clear();
      _companyLogo = null;
      _companyType = 'online';
    });
  }

  Future<void> _submitCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseImage == null || _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course image and video are required')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload files to Supabase
      final imageUrl = await _uploadFile(_courseImage!, 'course-images');
      final videoUrl = await _uploadFile(_videoFile!, 'course-videos');

      List<String> roadmapUrls = [];
      for (var image in _roadmapImages) {
        final url = await _uploadFile(image, 'roadmap-images');
        roadmapUrls.add(url);
      }

      // Upload course data
      final courseResponse = await _supabase.from('courses').insert({
        'name': _courseNameController.text,
        'description': _courseDescriptionController.text,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'roadmap_images': roadmapUrls,
      }).select();

      if (courseResponse.isEmpty) throw Exception('Failed to create course');

      final courseId = courseResponse.first['id'];

      // Upload companies data
      for (var company in _companies) {
        String? logoUrl;
        if (company['logo'] != null) {
          logoUrl = await _uploadFile(company['logo'] as XFile, 'company-logos');
        }

        await _supabase.from('companies').insert({
          'course_id': courseId,
          'name': company['name'],
          'link': company['link'],
          'logo_url': logoUrl,
          'type': company['type'],
        });
      }

      // Hide loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _courseImage = null;
        _videoFile = null;
        _roadmapImages = [];
        _companies = [];
      });
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: ${e.toString()}');
    }
  }

  Widget _buildImagePreview(XFile? file) {
    if (file == null) return const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        file.path,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(file.path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildVideoPreview(XFile? file) {
    if (file == null) return const SizedBox.shrink();

    return const Icon(Icons.video_library, size: 50);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Upload New Course',
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2252A1)), // Leading icon color
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Course Details'),


                      // Course name
                      TextFormField(
                        controller: _courseNameController,
                        decoration: InputDecoration(
                          labelText: 'Course Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Course name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Course description
                      TextFormField(
                        controller: _courseDescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Course Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Course description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Course image
                      const Text('Course Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.image),
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            label: const Text('Select Image'),
                          ),
                          const SizedBox(width: 16),
                          if (_courseImage != null)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImagePreview(_courseImage),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Course video
                      const Text('Course Video:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.video_library),
                            onPressed: _pickVideo,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            label: const Text('Select Video'),
                          ),
                          const SizedBox(width: 16),
                          if (_videoFile != null)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: _buildVideoPreview(_videoFile)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Roadmap images
                      const Text('Roadmap Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        onPressed: _pickRoadmapImages,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        label: const Text('Select Roadmap Images'),
                      ),
                      const SizedBox(height: 8),
                      if (_roadmapImages.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _roadmapImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImagePreview(_roadmapImages[index]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Companies section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Offering Companies'),

                      // Company name
                      TextFormField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Company link
                      TextFormField(
                        controller: _companyLinkController,
                        decoration: InputDecoration(
                          labelText: 'Company Website',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      // Company type
                      const Text('Company Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Online'),
                              value: 'online',
                              groupValue: _companyType,
                              onChanged: (value) {
                                setState(() {
                                  _companyType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Offline'),
                              value: 'offline',
                              groupValue: _companyType,
                              onChanged: (value) {
                                setState(() {
                                  _companyType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Company logo
                      const Text('Company Logo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.image),
                            onPressed: _pickCompanyLogo,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            label: const Text('Select Logo'),
                          ),
                          const SizedBox(width: 16),
                          if (_companyLogo != null)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImagePreview(_companyLogo),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Add company button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addCompany,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            backgroundColor: Color(0xFF2252A1),
                          ),
                          label: const Text('Add Company', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Added companies list
                      if (_companies.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Added Companies:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _companies.length,
                              itemBuilder: (context, index) {
                                final company = _companies[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: company['logo'] != null
                                        ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _buildImagePreview(company['logo']),
                                    )
                                        : const Icon(Icons.business),
                                    title: Text(company['name']),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(company['link'] ?? ''),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(
                                            company['type'] == 'online' ? 'Online' : 'Offline',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: company['type'] == 'online'
                                              ? Colors.blue.shade100
                                              : Colors.green.shade100,
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _companies.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: _submitCourse,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Upload Course',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}