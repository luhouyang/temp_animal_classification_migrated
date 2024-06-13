import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _loading = true;
  late File _image;
  final picker = ImagePicker(); //allows us to pick image from gallery or camera

  String pred = "";

  @override
  void initState() {
    //initS is the first function that is executed by default when this class is called
    super.initState();
  }

  @override
  void dispose() {
    //dis function disposes and clears our memory
    super.dispose();
  }

  classifyImage(File image) async {
    setState(() {
      _loading = true;
    });
    //this function runs the model on the image
    final interpreter =
        await tfl.Interpreter.fromAsset('assets/model_unquant.tflite');

    Uint8List imageData = image.readAsBytesSync();
    img.Image pngImage = img.decodeImage(imageData)!;
    img.Image resizedImage =
        img.copyResize(pngImage, width: 224, height: 224, maintainAspect: true);
    List<List<List<List<double>>>> input =
        _convertToCorrectInputShape(resizedImage, 224, 224);

    debugPrint(input.shape.toString());
    var output = List.filled(5, 0).reshape([1, 5]);

    interpreter.run(input, output);

    int argmax = 0;
    double maxValue = output[0][0];

    for (int i = 0; i < output[0].length; i++) {
      maxValue = math.max(maxValue, output[0][i]);
    }

    argmax = output[0].indexOf(maxValue);

    List<String> classes = [
      'Elephant',
      'Kangaroo',
      'Panda',
      'Penguin',
      'Tiger'
    ];
    debugPrint(output.toString());
    debugPrint(argmax.toString());
    debugPrint(classes[argmax]);
    interpreter.close();

    setState(() {
      _loading = false;
      pred = classes[argmax];
    });
  }

  List<List<List<List<double>>>> _convertToCorrectInputShape(
      img.Image image, int width, int height) {
    List<List<List<List<double>>>> inputList = List.generate(
      1,
      (_) => List.generate(
        height,
        (_) => List.generate(
          width,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        inputList[0][y][x][0] = double.tryParse(pixel.r.toString())!;
        inputList[0][y][x][1] = double.tryParse(pixel.g.toString())!;
        inputList[0][y][x][2] = double.tryParse(pixel.b.toString())!;
      }
    }

    return inputList;
  }

  pickImage() async {
    //this function to grab the image from camera
    var image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
  }

  pickGalleryImage() async {
    //this function to grab the image from gallery
    var image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        title: Text(
          'Animal Classification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 23,
          ),
        ),
      ),
      body: Container(
        color: Color.fromRGBO(68, 190, 255, 0.8),
        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 50),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Center(
                  child: _loading == true
                      ? null //show nothing if no picture selected
                      : Container(
                          child: Column(
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.width * 0.5,
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.file(
                                    _image,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Divider(
                                height: 25,
                                thickness: 1,
                              ),
                              // ignore: unnecessary_null_comparison
                              pred.isNotEmpty
                                  ? Text(
                                      'The animal is: ${pred}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  : Container(),
                              Divider(
                                height: 25,
                                thickness: 1,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Container(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 200,
                        alignment: Alignment.center,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Take A Photo',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: pickGalleryImage,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 200,
                        alignment: Alignment.center,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Pick From Gallery',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
