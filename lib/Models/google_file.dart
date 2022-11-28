class GoogleFile {
  final String? gFileName;
  final List<int>? gFileData;

  GoogleFile({this.gFileName, this.gFileData});

  factory GoogleFile.fromMap(Map<String, dynamic> json) =>
      GoogleFile(
        gFileData: json["gFileData"],
        gFileName: json["gFileName"]
      );

  Map<String, dynamic> toMap() => {"gFileData" : gFileData, "gFileName" : gFileName};
}