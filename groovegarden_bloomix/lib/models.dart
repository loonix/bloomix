class Session {
  String name;
  List<Track> tracks;

  Session(this.name, this.tracks);
}

class Track {
  String filePath;
  Duration startTime;

  Track(this.filePath, this.startTime);
}
