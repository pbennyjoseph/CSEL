import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a new Link'),
      ),
      body: Center(
        child: MyCustomForm(),
      ),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<MyCustomForm>
    with SingleTickerProviderStateMixin {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  final _myController = TextEditingController();
  final _myUrlController = TextEditingController();

  bool isLoading = false;

  void dispose() {
    // Clean up the controller when the widget is disposed.
    _myController.dispose();
    _myUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Provider.of<DataConnectionStatus>(context) ==
            DataConnectionStatus.disconnected
        ? Center(
            child: Text('No Internet'),
          )
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _myController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _myUrlController,
                    decoration: InputDecoration(
                      labelText: "URL",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: RaisedButton(
                      elevation: 0,
                      onPressed: () async {
                        // Validate returns true if the form is valid, or false
                        // otherwise.
                        if (_formKey.currentState.validate()) {
                          setState(() {
                            isLoading = true;
                          });
                          // If the form is valid, display a Snackbar.
                          await Firestore.instance
                              .collection('CSEL_links')
                              .add({
                            'url': _myUrlController.text,
                            'title': _myController.text,
                            'createTime': DateTime.now().millisecondsSinceEpoch,
                            'clicks': 0,
                            'votes': 0,
                          });

                          final snackBar = SnackBar(
                            content: Text("Link published successfully"),
                          );
                          Scaffold.of(context).showSnackBar(snackBar);
                          setState(() {
                            isLoading = false;
                          });
//                          Navigator.of(context).pop();
                        }
                      },
                      child: AnimatedSize(
                        duration: Duration(milliseconds: 250),
                        vsync: this,
                        curve: Curves.linear,
                        child: isLoading
                            ? SizedBox(
                                height: 24.0,
                                width: 24.0,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text('Submit'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
