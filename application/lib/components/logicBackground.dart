String getBackground(String? main) {
  switch(main?.toLowerCase()) {
    case "rain":
    case "drizzle":
      return "assets/images/rain.jpg";


    case "snow":
      return "assets/images/snow.jpg";


    case "clear":
      return "assets/images/sunny.jpg";


    case "thunderstorm":
      return "assets/images/thunderstorm.jpg";


    case "clouds":
      return "assets/images/windy.jpg";

    case "atmosphere":
      return "assets/images/mist.jpg";
    default:
      return "assets/images/sunny.jpg";
  }
}