String getBackground(String? main) {
  switch(main?.toLowerCase()) {
    case "rain":
    case "drizzle":
      return "assets/images/rain.png";


    case "snow":
      return "assets/images/snow.png";


    case "clear":
      return "assets/images/sunny.png";


    case "thunderstorm":
      return "assets/images/thunderstorm.png";


    case "clouds":
      return "assets/images/windy.png";


    default:
      return "assets/images/sunny.png";
  }
}