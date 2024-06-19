import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  List<String> names = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    final response = await http.get(Uri.parse('https://anime1.me'));

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      print(response.body) ;  // print to debug
      // final nameElements = document.querySelectorAll('selector-for-names'); // Update with correct selector
      final nameElements = document.querySelectorAll('main section ul li');
        
      // Print the extracted elements to debug
      nameElements.forEach((element) => print(element.text));
      setState(() {
        names = nameElements.map((element) => element.text).toList();
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
        title: Text('Names List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(names[index]),
                );
              },
            ),
    );
  }
}