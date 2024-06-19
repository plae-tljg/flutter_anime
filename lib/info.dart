
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  List<String> names = [];
  bool isLoading = true;
  String fetchedHtml = '';

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    final response = await http.get(Uri.parse('https://anime1.me'));

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);

      // Save the fetched HTML to display it
      setState(() {
        fetchedHtml = response.body;
      });

      // Use the correct selector for the elements you want to extract
      final nameElements = document.querySelectorAll('main section ul li');

      // Print the extracted elements to debug
      for (var element in nameElements) {
        print(element.text);
      }

      setState(() {
        names = nameElements.map((element) => element.text.trim()).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load webpage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Names List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fetched HTML:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(fetchedHtml),
                  const SizedBox(height: 20),
                  const Text(
                    'Names List:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(names[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}