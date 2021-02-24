import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _rows = 15;
  List<PasajeroModel> list = [];
  ScrollController _scrollController = new ScrollController();
  final PagingController<int, PasajeroModel> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _counter++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: _asyncCustomerProjectUsingPackage()),
    );
  }

  _asyncCustomerProjectUsingPackage() {
    return PagedListView<int, PasajeroModel>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<PasajeroModel>(
          itemBuilder: (context, item, index) {
        return Card(
          child: Column(
            children: [
              Text(item.id),
              Text(item.name, style: TextStyle(fontSize: 30))
            ],
          ),
        );
      }, newPageProgressIndicatorBuilder: (_) {
        return SpinKitThreeBounce(
          color: Colors.black,
          size: 40.0,
        );
      }),
    );
  }

  _asyncCustomerProjects() {
    return FutureBuilder<List<PasajeroModel>>(
      future: getPasajeros(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            list.insertAll(_counter * _rows, snapshot.data);
          }
          return Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              ListView.builder(
                  itemCount: list.length,
                  controller: _scrollController,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: Column(
                        children: [
                          Text(list[index].id),
                          Text(list[index].name, style: TextStyle(fontSize: 30))
                        ],
                      ),
                    );
                  }),
              SizedBox(
                height: 50,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Visibility(
                    visible:
                        snapshot.connectionState == ConnectionState.waiting,
                    child: SpinKitThreeBounce(
                      color: Colors.black,
                      size: 40.0,
                    ),
                  ),
                ),
              )
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Future<List<PasajeroModel>> getPasajeros() async {
    final response = await http.get(
        'https://api.instantwebtools.net/v1/passenger?page=' +
            _counter.toString() +
            '&size=' +
            _rows.toString());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonMapped = jsonDecode(response.body);
      List<PasajeroModel> webList = List<PasajeroModel>.from(
          jsonMapped["data"].map((x) => PasajeroModel.fromMap(x)));
      return webList;
    } else {
      throw Exception('Failed to load album');
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems =
          await getPasajeros(); //RemoteApi.getCharacterList(pageKey, _pageSize);
      final isLastPage = newItems.length < _rows;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      _counter++;
    } catch (error) {
      _pagingController.error = error;
    }
  }
}

class PasajeroModel {
  String id;
  String name;

  PasajeroModel({this.id, this.name});

  factory PasajeroModel.fromMap(Map<String, dynamic> json) {
    return PasajeroModel(
      id: json['_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toMap() => {
        "_id": id,
        "name": name,
      };
}
