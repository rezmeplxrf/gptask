// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, avoid_print, depend_on_referenced_packages

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voss/dictionary/clickable_text.dart';
import 'package:voss/widgets/hoverovereffect.dart';
import 'package:voss/dictionary/dictionary_popup.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:voss/widgets/text_to_speech_helper.dart';

int _cardSet = 2;

class FlashcardModel {
  final String id;
  final String text;
  final Timestamp timestamp;
  final String conversation1;
  final String conversation2;
  final String variation1;
  final String variation2;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? image7;
  final String? image8;
  final String? image9;
  final String? image10;
  final String c_voca1;
  final String c_voca2;
  final String v_voca1;
  final String v_voca2;

  FlashcardModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.conversation1,
    required this.conversation2,
    required this.variation1,
    required this.variation2,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.image7,
    this.image8,
    this.image9,
    this.image10,
    required this.c_voca1,
    required this.c_voca2,
    required this.v_voca1,
    required this.v_voca2,
  });

  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel(
      id: doc.id,
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      conversation1: data['conversation1'] ?? '',
      conversation2: data['conversation2'] ?? '',
      variation1: data['variation1'] ?? '',
      variation2: data['variation2'] ?? '',
      image1: data['image1'],
      image2: data['image2'],
      image3: data['image3'],
      image4: data['image4'],
      image5: data['image5'],
      image6: data['image6'],
      image7: data['image7'],
      image8: data['image8'],
      image9: data['image9'],
      image10: data['image10'],
      c_voca1: data['c_voca1'] ?? '',
      c_voca2: data['c_voca2'] ?? '',
      v_voca1: data['v_voca1'] ?? '',
      v_voca2: data['v_voca2'] ?? '',
    );
  }
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

int limit = 20;

class FlashcardRepository {
  Future<List<FlashcardModel>> getRandomFlashcards(
      String userId, int limit) async {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('english')
        .orderBy(FieldPath.documentId)
        .limit(limit);

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    int availableDocs = querySnapshot.docs.length;

    List<FlashcardModel> flashcards = querySnapshot.docs
        .map((doc) => FlashcardModel.fromFirestore(doc))
        .toList();

    flashcards.shuffle();

    return flashcards.take(min(limit, availableDocs)).toList();
  }

  Future<void> saveWrongCardsStats(
      String userId, List<String> wrongCards) async {
    final currentDate = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
    final docId = '$userId-$formattedDate';

    final userStatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc(docId);

    await userStatsRef.set({
      'wrongCards': wrongCards,
      'timestamp': Timestamp.now(),
      'date': formattedDate,
    }, SetOptions(merge: true));
  }

  Future<List<DateTime>> getStatsData(String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .orderBy('date', descending: true)
        .limit(30)
        .get();

    List<DateTime> statsData = [];

    for (DocumentSnapshot document in querySnapshot.docs) {
      DateTime date = DateTime.parse(document['date']).toLocal();
      statsData.add(date);
    }

    return statsData;
  }

  Future<List<String>> loadLastWrongCardsStats(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    final data = querySnapshot.docs.first.data();
    return List<String>.from(data['wrongCards']);
  }

  Future<List<FlashcardModel>> getLast20DaysFlashcards(
      String userId, int limit, int ratio) async {
    final DateTime tenDaysAgo =
        DateTime.now().subtract(const Duration(days: 10));
    final int limit1 = (limit * (ratio / 10)).ceil();
    final int limit2 = (limit * (3 / 10)).ceil();

    QuerySnapshot snapshot1;
    QuerySnapshot snapshot2;

    try {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isLessThanOrEqualTo: tenDaysAgo)
          .limit(limit1)
          .get();
    } catch (error) {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isLessThanOrEqualTo: tenDaysAgo)
          .limit(limit1)
          .get(const GetOptions(source: Source.server));
    }

    try {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isGreaterThan: tenDaysAgo)
          .limit(limit)
          .get();
    } catch (error) {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isGreaterThan: tenDaysAgo)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
    }

    if (snapshot1.docs.isEmpty) {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isLessThanOrEqualTo: tenDaysAgo)
          .limit(limit1)
          .get();
    }

    if (snapshot2.docs.isEmpty) {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('timestamp', isGreaterThan: tenDaysAgo)
          .limit(limit)
          .get();
    }

    List<FlashcardModel> flashcards1 =
        snapshot1.docs.map((doc) => FlashcardModel.fromFirestore(doc)).toList();
    List<FlashcardModel> flashcards2 =
        snapshot2.docs.map((doc) => FlashcardModel.fromFirestore(doc)).toList();

    if (flashcards1.isEmpty && flashcards2.isEmpty) {
      return [];
    }

    flashcards1.shuffle();
    flashcards2.shuffle();

    if (flashcards1.length < limit1) {
      int extraCardsNeeded = limit1 - flashcards1.length;
      return flashcards1 + flashcards2.take(limit2 + extraCardsNeeded).toList();
    } else if (flashcards2.length < limit2) {
      int extraCardsNeeded = limit2 - flashcards2.length;
      return flashcards1.take(limit1 + extraCardsNeeded).toList() + flashcards2;
    } else {
      return flashcards1.take(limit1).toList() +
          flashcards2.take(limit2).toList();
    }
  }

  Future<List<FlashcardModel>> getOldestFlashcards(
      String userId, int limit, int ratio) async {
    final int limit1 = (limit * (ratio / 10)).round();
    final int limit2 = (limit * (3 / 10)).round();

    QuerySnapshot snapshot1;
    QuerySnapshot snapshot2;

    try {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: false)
          .limit(limit1)
          .get();
    } catch (error) {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: false)
          .limit(limit1)
          .get(const GetOptions(source: Source.server));
    }

    try {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
    } catch (error) {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
    }

    if (snapshot1.docs.isEmpty) {
      snapshot1 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: false)
          .limit(limit1)
          .get(const GetOptions(source: Source.server));
    }

    if (snapshot2.docs.isEmpty) {
      snapshot2 = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
    }
    Set<String> seenDocIds = {};
    List<FlashcardModel> flashcards1 =
        snapshot1.docs.map((doc) => FlashcardModel.fromFirestore(doc)).toList();
    List<FlashcardModel> flashcards2 =
        snapshot2.docs.map((doc) => FlashcardModel.fromFirestore(doc)).toList();

    flashcards1.removeWhere((flashcard) => !seenDocIds.add(flashcard.id));
    flashcards2.removeWhere((flashcard) => !seenDocIds.add(flashcard.id));

    if (flashcards1.isEmpty && flashcards2.isEmpty) {
      return [];
    }

    flashcards1.shuffle();
    flashcards2.shuffle();

    if (flashcards1.length < limit1) {
      int extraCardsNeeded = limit1 - flashcards1.length;
      return flashcards1 + flashcards2.take(limit2 + extraCardsNeeded).toList();
    } else if (flashcards2.length < limit2) {
      int extraCardsNeeded = limit2 - flashcards2.length;
      return flashcards1.take(limit1 + extraCardsNeeded).toList() + flashcards2;
    } else {
      return flashcards1.take(limit1).toList() +
          flashcards2.take(limit2).toList();
    }
  }

  Future<List<FlashcardModel>> getStarredFlashcards(
      String userId, int limit) async {
    QuerySnapshot querySnapshot;
    try {
      querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('starred', isEqualTo: true)
          .limit(limit)
          .get();
    } catch (error) {
      querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('english')
          .where('starred', isEqualTo: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
    }

    if (querySnapshot.size == 0) {
      return getRandomFlashcards(userId, limit);
    } else {
      return querySnapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();
    }
  }

  Future<List<FlashcardModel>> getFlashcardsByOption(
      String userId, int limit, String option) {
    if (option == 'Recent') {
      return getLast20DaysFlashcards(userId, limit, 7);
    } else if (option == 'Old') {
      return getOldestFlashcards(userId, limit, 7);
    } else if (option == 'Star') {
      return getStarredFlashcards(userId, limit);
    } else {
      throw Exception('Invalid option selected');
    }
  }
}

class FlashcardWidget extends StatefulWidget {
  final FlashcardModel flashcard;
  final int currentIndex;
  final int totalCount;
  final int rightCount;
  final int wrongCount;
  final ValueChanged<int> onNext;
  final VoidCallback? onRight;
  final VoidCallback? onWrong;
  final VoidCallback? onFinish;

  const FlashcardWidget({
    Key? key,
    required this.flashcard,
    required this.currentIndex,
    required this.totalCount,
    required this.rightCount,
    required this.wrongCount,
    required this.onNext,
    this.onRight,
    this.onWrong,
    this.onFinish,
  }) : super(key: key);

  @override
  FlashcardWidgetState createState() => FlashcardWidgetState();
}

class FlashcardWidgetState extends State<FlashcardWidget> {
  int _fold = 0;
  int _imageIndex = 1;
  Timer? _imageTimer;
  Color _animationColor = Colors.white;
  bool _showCheckIcon = false;
  bool _showCrossIcon = false;
  bool playedText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fold = 1;
        _fold = 0;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isFirstTimeVisitor().then((bool isFirstTime) {
        if (isFirstTime) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showWelcomeDialog(context);
          });

          SharedPreferences.getInstance().then((prefs) {
            prefs.setBool('isFirstTimeflash', false);
          });
        }
      });
    });
    _startImageTimer();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx < -800) {
      setState(() {
        _animationColor = Colors.green.withOpacity(0.5);
        _showCheckIcon = true;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onRight?.call();
        widget.onNext(1);
        setState(() {
          _fold = 0;
          _animationColor = Colors.white;
          _showCheckIcon = false;
          playedText = false;
        });
      });
    } else if (details.velocity.pixelsPerSecond.dx > 800) {
      setState(() {
        _animationColor = Colors.red.withOpacity(0.5);
        _showCrossIcon = true;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onWrong?.call();
        widget.onNext(1);
        setState(() {
          _fold = 0;
          _animationColor = Colors.white;
          _showCrossIcon = false;
          playedText = false;
        });
      });
    } else if (details.velocity.pixelsPerSecond.dy > 800) {
      setState(() {
        _animationColor = Colors.yellow.withOpacity(0.5);
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _fold = (_fold + 1) % 2;
          _animationColor = Colors.white;
        });
      });
    }
  }

  void _startImageTimer() {
    const Duration interval = Duration(seconds: 3);
    List<String> availableImages = _getAvailableImages();
    if (availableImages.isEmpty) return;

    _imageTimer = Timer.periodic(interval, (timer) {
      if (mounted && _fold == 0) {
        setState(() {
          _imageIndex = (_imageIndex % availableImages.length) + 1;
        });
      }
    });
  }

  Future<bool> isFirstTimeVisitor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTimeflash') ?? true;
    return isFirstTime;
  }

  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              title: Text('flashpage'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              content: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    TextSpan(
                        text: 'flashbody'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                    const TextSpan(text: '\n\n'),
                    TextSpan(
                      text: 'flashbody2'.tr,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'.tr),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_fold == 0) {
                setState(() {
                  _imageIndex = (_imageIndex % 10) + 1;
                });
              }
            },
            onHorizontalDragEnd: _handleSwipe,
            onVerticalDragEnd: _handleSwipe,
            child: Stack(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                color: _animationColor,
                child: Card(
                  child: _buildCardContent(),
                ),
              ),
              if (_showCheckIcon)
                Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.green.withOpacity(0.5),
                    size: 120,
                  ),
                ),
              if (_showCrossIcon)
                Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.red.withOpacity(0.5),
                    size: 120,
                  ),
                ),
            ]),
          ),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                widget.onWrong?.call();
                widget.onNext(1);
                setState(() {
                  _fold = 0;
                  playedText = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.question_mark),
              onPressed: () => setState(() {
                _fold = (_fold + 1) % 2;
                playedText = false;
              }),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                widget.onRight?.call();
                widget.onNext(1);
                setState(() {
                  _fold = 0;
                  playedText = false;
                });
              },
            ),
          ],
        ),
      ],
    );
  }




  Widget _buildCardContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildModeContent(),
    );
  }

  Widget _buildModeContent() {
    switch (_cardSet) {
      case 0:
        return _fold == 0 ? _buildConversationsContent() : _buildTextContent();
      case 1:
        return _fold == 0 ? _buildImageContent() : _buildTextContent();
      case 2:
        return _fold == 0 ? _buildTextContent() : _buildDicContent();
      default:
        return const SizedBox.shrink();
    }
  }

  List<String> _getAvailableImages() {
    List<String> availableImages = [];
    if (widget.flashcard.image1 != null) {
      availableImages.add(widget.flashcard.image1!);
    }
    if (widget.flashcard.image2 != null) {
      availableImages.add(widget.flashcard.image2!);
    }
    if (widget.flashcard.image3 != null) {
      availableImages.add(widget.flashcard.image3!);
    }
    if (widget.flashcard.image4 != null) {
      availableImages.add(widget.flashcard.image4!);
    }
    if (widget.flashcard.image5 != null) {
      availableImages.add(widget.flashcard.image5!);
    }
    if (widget.flashcard.image6 != null) {
      availableImages.add(widget.flashcard.image6!);
    }
    if (widget.flashcard.image7 != null) {
      availableImages.add(widget.flashcard.image7!);
    }
    if (widget.flashcard.image8 != null) {
      availableImages.add(widget.flashcard.image8!);
    }
    if (widget.flashcard.image9 != null) {
      availableImages.add(widget.flashcard.image9!);
    }
    if (widget.flashcard.image10 != null) {
      availableImages.add(widget.flashcard.image10!);
    }
    return availableImages;
  }

  Widget _buildImageContent() {
    List<String> availableImages = _getAvailableImages();

    if (availableImages.isNotEmpty) {
      String imageURL =
          availableImages[(_imageIndex - 1) % availableImages.length];
      return GestureDetector(
        onTap: () {
          setState(() {
            if (availableImages.length > 1) {
              _imageIndex = (_imageIndex % availableImages.length) + 1;
            }
          });
        },
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Image.network(
              imageURL,
              fit: BoxFit.cover,
              key: ValueKey<String>(imageURL),
            ),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey,
        child: Center(child: Text('noimage'.tr)),
      );
    }
  }

  Widget _buildTextContent() {
    if (!playedText) {
      playText(widget.flashcard.text, defaultSingleVoice);
      playedText = true;
    }
    return Center(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClickableText(
                word: widget.flashcard.text,
                child: HoverHighlight(
                  child: Text(
                    widget.flashcard.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () =>
                  playText(widget.flashcard.text, defaultSingleVoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDicContent() {
    final dictionaryController = Get.find<DictionaryController>();

    return Container(
      color: Theme.of(context).colorScheme.onPrimary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              FutureBuilder(
                future: Future.wait([
                  dictionaryController.fetchWordMeaning(widget.flashcard.text),
                  dictionaryController.fetchAiResponse(widget.flashcard.text),
                ]),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Expanded(
                      child: DictionaryPopup(
                          dictionaryController: dictionaryController),
                    );
                  } else {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsContent() {
    List<Widget> conversationFields = [];

    List<String> conversations = [
      widget.flashcard.conversation1,
      widget.flashcard.conversation2,
      widget.flashcard.variation1,
      widget.flashcard.variation2,
    ];

    List<String> vocas = [
      widget.flashcard.c_voca1,
      widget.flashcard.c_voca2,
      widget.flashcard.v_voca1,
      widget.flashcard.v_voca2,
    ];

    for (int i = 0; i < conversations.length; i++) {
      String conversation = conversations[i];
      bool isVariation = i >= 2;

      conversationFields.add(const Divider());
      conversationFields.addAll(
        _buildConversation(conversation, i, isVariation),
      );
      conversationFields.add(_buildVocaDisplay(vocas[i]));
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: conversationFields,
    );
  }

  Widget _buildVocaDisplay(String voca) {
    List<Widget> clickableTexts = _buildClickableTexts(voca);

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(top: 8.0, bottom: 3.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: clickableTexts,
      ),
    );
  }

  List<Widget> _buildClickableTexts(String data) {
    data = data.replaceAll('.', '');
    List<String> items = data.split(',');
    List<Widget> texts = [];

    for (int i = 0; i < items.length; i++) {
      String item = items[i].trim();
      texts.add(
        HoverHighlight(
          child: ClickableText(
            word: item,
            child: Text(
              item,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ),
        ),
      );
      if (i != items.length - 1) {
        texts.add(const Text(', '));
      }
    }
    return texts;
  }
}

List<Widget> _buildConversation(
    String conversation, int conversationIndex, bool isVariation) {
  List<Widget> messages = [];
  RegExp pattern = RegExp(r'(A:|B:)(.*?)(?=A:|B:|$)');
  Iterable<Match> matches = pattern.allMatches(conversation);
  int messageIndex = 0;

  for (Match match in matches) {
    String role = match.group(1)!;
    String content = match.group(2)!.trim();
    bool isA = role.trim() == 'A:';

    // ignore: unnecessary_brace_in_string_interps
    String uniqueId = 'message_${conversationIndex}_${messageIndex}';
    messages.add(_buildChatBubble(
        content, isA, conversationIndex, uniqueId, isVariation));
    messageIndex++;
  }

  return messages;
}

String _processContent(String content, bool isVariation) {
  if (!isVariation) {
    return content.replaceAllMapped(RegExp(r'\*(.*?)\*'), (Match match) {
      return '_' * match.group(1)!.length;
    });
  }
  return content;
}

Widget _buildChatBubble(String content, bool isA, int conversationIndex,
    String id, bool isVariation) {
  content = _processContent(content, isVariation);
  return Align(
    alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isA ? Colors.blue[100] : Colors.green[100],
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Text(content),
    ),
  );
}

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen(
      {Key? key, required this.limit, required this.flashcardOption})
      : super(key: key);
  final int limit;
  final String flashcardOption;
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (Route<dynamic> route) => false);
          });
          return const SizedBox.shrink();
        }

        return FlashcardsAuthenticatedScreen(
            user: user, limit: limit, flashcardOption: flashcardOption);
      },
    );
  }
}

class FlashcardsAuthenticatedScreen extends StatefulWidget {
  final User user;
  final int limit;
  final String flashcardOption;
  const FlashcardsAuthenticatedScreen(
      {Key? key,
      required this.user,
      required this.limit,
      required this.flashcardOption})
      : super(key: key);

  @override
  FlashcardsAuthenticatedScreenState createState() =>
      FlashcardsAuthenticatedScreenState();
}

class FlashcardsAuthenticatedScreenState
    extends State<FlashcardsAuthenticatedScreen> with WidgetsBindingObserver {
  final FlashcardRepository _repository = FlashcardRepository();
  late Future<List<FlashcardModel>> _futureFlashcards;
  int _currentIndex = 0;
  int _totalCount = 0;
  int _rightCount = 0;
  int _wrongCount = 0;
  Set<String> wrongFlashcards = <String>{};
  Set<String> rightFlashcards = <String>{};
  DateTime? _lastFetchedDate;
  List<DateTime>? _statsData;
  List<FlashcardModel>? _cachedFlashcards;

  void _shuffleFlashcards(List<FlashcardModel> flashcards) {
    flashcards.shuffle();
  }

  Future<void> _loadWrongCards() async {
    List<String> wrongCards =
        await _repository.loadLastWrongCardsStats(widget.user.uid);
    List<FlashcardModel> wrongFlashcardModels = [];
    if (_cachedFlashcards != null) {
      for (String wrongText in wrongCards) {
        FlashcardModel? foundCard = _cachedFlashcards!
            .firstWhereOrNull((card) => card.text == wrongText);
        if (foundCard != null) {
          wrongFlashcardModels.add(foundCard);
        }
      }

      _shuffleFlashcards(wrongFlashcardModels);

      if (wrongFlashcardModels.isNotEmpty) {
        setState(() {
          _futureFlashcards = Future.value(wrongFlashcardModels);
          _totalCount = wrongFlashcardModels.length;
          _currentIndex = 0;
        });
      } else {
        print("No wrong cards found");
      }
    } else {
      print("Cached flashcards are not available");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _futureFlashcards = _repository.getFlashcardsByOption(
        widget.user.uid, widget.limit, widget.flashcardOption);
    _futureFlashcards.then((flashcards) {
      _shuffleFlashcards(flashcards);
      if (flashcards.isNotEmpty) {}
      setState(() {
        _totalCount = flashcards.length;
        _currentIndex = 0;
        _wrongCount = 0;
        _rightCount = 0;
        _cachedFlashcards = flashcards;
        _fetchStatsData();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/', (Route<dynamic> route) => false);
    }
  }

  Future<void> _fetchStatsData() async {
    DateTime now = DateTime.now();
    String currentDate = DateFormat('yyyy-MM-dd').format(now);

    if (_lastFetchedDate == null ||
        _lastFetchedDate!.toIso8601String() != currentDate) {
      _statsData = await _repository.getStatsData(widget.user.uid);
      _lastFetchedDate = now;
    }
  }

  void _displayStatsData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ResultsWidget(
              statsData: _statsData ?? [],
              consecutiveDays:
                  _statsData != null ? _calculateConsecutiveDays() : 0,
            );
          },
        );
      },
    );
  }

  int _calculateConsecutiveDays() {
    int consecutiveDays = 0;
    DateTime currentDate = DateTime.now();

    for (int i = 0; i < _statsData!.length; i++) {
      DateTime previousDate =
          currentDate.subtract(Duration(days: consecutiveDays + 1));
      if (isSameDay(_statsData![i], previousDate)) {
        consecutiveDays++;
      } else if (isSameDay(_statsData![i], currentDate)) {
        continue;
      } else {
        break;
      }
    }
    return consecutiveDays;
  }

  void _showResultsDialog(BuildContext context, {VoidCallback? onResult}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool gotItAllRight = wrongFlashcards.isEmpty;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Right: $_rightCount Wrong: $_wrongCount Total: $_totalCount",
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                gotItAllRight
                    ? Text(
                        "gotitallright".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.green,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'incorredcards'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                            },
                            children: [
                              for (int i = 0;
                                  i < wrongFlashcards.length;
                                  i += 3)
                                TableRow(
                                  children: [
                                    for (int j = i; j < i + 3; j++)
                                      if (j < wrongFlashcards.length)
                                        Text(wrongFlashcards.elementAt(j))
                                      else
                                        Container(),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetCounters();

                        setState(() {
                          _shuffleFlashcards(_cachedFlashcards!);
                          _futureFlashcards = Future.value(_cachedFlashcards);
                          _totalCount = _cachedFlashcards!.length;
                        });
                      },
                      child: Text(
                        'restart'.tr,
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        await _repository.saveWrongCardsStats(
                            widget.user.uid, wrongFlashcards.toList());
                        Navigator.of(context).pop();
                        _resetCounters();

                        setState(() {
                          _loadWrongCards();
                        });
                      },
                      child: Text(
                        'retry'.tr,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        await _repository.saveWrongCardsStats(
                            widget.user.uid, wrongFlashcards.toList());
                        _resetCounters();
                        Navigator.of(context).pop();

                        if (onResult != null) {
                          onResult();
                        }
                      },
                      child: Text(
                        'close'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: HoverHighlight(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _resetCounters();
              });
              Get.back();
            },
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
            ),
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            "${_currentIndex + 1}/$_totalCount",
            key: ValueKey<int>(_currentIndex),
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    " $_rightCount",
                    key: ValueKey<int>(_rightCount),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    " $_wrongCount",
                    key: ValueKey<int>(_wrongCount),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: _cardSet == 0
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.forum),
              onPressed: () {
                setState(() {
                  _cardSet = 0;
                });
              },
            ),
          ),
          Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: _cardSet == 1
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.panorama_outlined),
              onPressed: () {
                setState(() {
                  _cardSet = 1;
                });
              },
            ),
          ),
          Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: _cardSet == 2
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () {
                setState(() {
                  _cardSet = 2;
                });
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<FlashcardModel>>(
        future: _futureFlashcards,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('error'.tr));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<FlashcardModel> flashcards = snapshot.data!;

          return FlashcardWidget(
            flashcard: flashcards[_currentIndex],
            currentIndex: _currentIndex,
            rightCount: _rightCount,
            wrongCount: _wrongCount,
            totalCount: _totalCount,
            onNext: (int step) {
              setState(() {
                _currentIndex = (_currentIndex + step + flashcards.length) %
                    flashcards.length;

                if (_currentIndex == 0 && (_rightCount + _wrongCount) > 0) {
                  _showResultsDialog(
                    context,
                    onResult: () {
                      _displayStatsData(context);
                    },
                  );
                }
              });
            },
            onRight: () {
              if (!rightFlashcards.contains(flashcards[_currentIndex].text) &&
                  !wrongFlashcards.contains(flashcards[_currentIndex].text)) {
                rightFlashcards.add(flashcards[_currentIndex].text);
                setState(() {
                  _rightCount++;
                });
              }
            },
            onWrong: () {
              if (!rightFlashcards.contains(flashcards[_currentIndex].text) &&
                  !wrongFlashcards.contains(flashcards[_currentIndex].text)) {
                wrongFlashcards.add(flashcards[_currentIndex].text);
                setState(() {
                  _wrongCount++;
                });
              }
            },
            onFinish: () {
              _resetCounters();
            },
          );
        },
      ),
    );
  }

  void _resetCounters() {
    setState(() {
      _rightCount = 0;
      _wrongCount = 0;
      wrongFlashcards.clear();
      rightFlashcards.clear();
      _currentIndex = 0;
    });
  }
}

class FlashcardsNavigator extends StatefulWidget {
  final int limit;
  final String flashcardOption;
  const FlashcardsNavigator(
      {Key? key, required this.limit, required this.flashcardOption})
      : super(key: key);

  @override
  FlashcardsNavigatorState createState() => FlashcardsNavigatorState();
}

class FlashcardsNavigatorState extends State<FlashcardsNavigator> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            return FlashcardsScreen(
                limit: widget.limit, flashcardOption: widget.flashcardOption);
          },
        );
      },
    );
  }
}

class ResultsWidget extends StatelessWidget {
  final List<DateTime> statsData;
  final int consecutiveDays;

  const ResultsWidget(
      {super.key, required this.statsData, this.consecutiveDays = 0});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: WillPopScope(
        onWillPop: () async {
          Get.offNamed('/Home');
          return true;
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${statsData.length} days",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Consecutive days: $consecutiveDays",
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Get.offNamed('/Home');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 30)),
                lastDay: DateTime.now(),
                focusedDay: DateTime.now(),
                availableGestures: AvailableGestures.none,
                eventLoader: (day) {
                  return statsData
                      .where((date) => isSameDay(date, day))
                      .toList();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
