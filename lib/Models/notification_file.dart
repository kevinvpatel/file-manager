class NotificationFile {

  final int? fileId;
  final String? fileName;
  final String? filePath;
  final String title;
  final String? description;
  final String dateTime;
  final String notificationId;
  final int? isFile;
  final int? isComplete;

  NotificationFile(
      {this.fileId,
      required this.fileName,
      required this.title,
      this.description,
      required this.dateTime,
      required this.notificationId,
      this.isComplete,
      required this.isFile,
      required this.filePath});

  factory NotificationFile.fromMap(Map<String, dynamic> json) =>
      NotificationFile(
        fileId: json['fileId'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        title: json['title'],
        description: json['description'],
        dateTime: json['dateTime'],
        notificationId: json['notificationId'],
        isFile: json['isFile'],
        isComplete: json['isComplete'],
      );

  Map<String, dynamic> toMap() => {
    'fileId' : fileId,
    'fileName' : fileName,
    'filePath' : filePath,
    'title' : title,
    'description' : description,
    'dateTime' : dateTime,
    'notificationId' : notificationId,
    'isFile' : isFile,
    'isComplete' : isComplete,
  };

}