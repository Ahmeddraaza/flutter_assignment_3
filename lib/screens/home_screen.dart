import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://newsapi.org/v2/top-headlines?country=us';
const String apiKey = 'abb021fcd9124fe4a756d19365dc0136';

class News {
  final String author;
  final String title;
  final String publishedAt;
  final String urlToImage;
  final String description;
  final String content;
  final String url;

  News({
    required this.author,
    required this.title,
    required this.publishedAt,
    required this.urlToImage,
    required this.description,
    required this.content,
    required this.url,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      author: json['author'] ?? 'Unknown',
      title: json['title'],
      publishedAt: json['publishedAt'],
      urlToImage: json['urlToImage'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      url: json['url'],
    );
  }
}

class NewsBloc extends Cubit<List<News>> {
  NewsBloc() : super([]);

  Future<void> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl&apiKey=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<News> articles = (data['articles'] as List)
            .map((article) => News.fromJson(article))
            .toList();
        emit(articles);
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Headline News',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Read Top News Today'),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/news.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
      body: BlocProvider(
        create: (_) => NewsBloc()..fetchNews(),
        child: BlocBuilder<NewsBloc, List<News>>(
          builder: (context, newsList) {
            if (newsList.isEmpty) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.white),
                      title: Container(
                        color: Colors.white,
                        height: 10.0,
                        width: double.infinity,
                      ),
                      subtitle: Container(
                        color: Colors.white,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    );
                  },
                ),
              );
            }

            return ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
                      _showModalBottomSheet(context, news);
                    },
                    child: Container(
                      height: 120,
                      child: Row(
                        children: [
                          // Displaying the image with error handling
                          news.urlToImage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10)),
                                  child: Image.network(
                                    news.urlToImage,
                                    height: double.infinity,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      } else {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    (loadingProgress.expectedTotalBytes ?? 1)
                                                : null,
                                          ),
                                        );
                                      }
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/download.png', // Placeholder image if the image cannot be loaded
                                        height: double.infinity,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10)),
                                  child: Image.asset(
                                    'assets/download.png', // Default fallback image
                                    height: double.infinity,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    news.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(news.author, style: TextStyle(fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDate(news.publishedAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Show the Modal Bottom Sheet with article details
  void _showModalBottomSheet(BuildContext context, News news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.urlToImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(news.urlToImage),
                  ),
                SizedBox(height: 8),
                Text(news.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                Text('By ${news.author} | ${_formatDate(news.publishedAt)}'),
                SizedBox(height: 8),
                Text(news.description),
                SizedBox(height: 8),
                Text(news.content),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _launchURL(news.url);
                  },
                  child: Text('View Article'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  String _formatDate(String publishedAt) {
    try {
      final dateTime = DateTime.parse(publishedAt);
      final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      return formattedDate;
    } catch (e) {
      return publishedAt;
    }
  }

  
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
