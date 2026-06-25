String getBackground(w) {

  String weather =
      w!.weatherMain ?? "";

  if(weather.contains("clear sky") || weather.contains("")){
    return "assets/images/rain.jpg";
  }

  if(weather.contains("Cloud")){
    return "assets/images/cloudy.jpg";
  }

  return "assets/images/sunny.jpg";
}