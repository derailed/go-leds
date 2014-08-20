app = angular.module('LedApp', ['ngRoute', 'templates'])

app.config ($routeProvider) ->
  $routeProvider.when '/',
    templateUrl: '/app.html'

app.controller 'LedCtrl', ($scope, $timeout, $http) ->
  $scope.svc_url  = "http://localhost:4500"
  $scope.done     = false
  $scope.playing  = true
  $scope.fft      = 64

  # $scope.track    =
  #   file: "http://localhost:8000/tracks/huffnpuff.mp3"
  #   low:
  #     band:    2
  #     triggers: [_.range(230,256)]
  #   mid:
  #     band:    $scope.fft/4
  #     triggers: [_.range(150,256)]
  #   high:
  #     band:    26
  #     triggers: [_.range(6,255)]

  $scope.track    =
    file: "http://localhost:8000/tracks/drum_slow.mp3"
    low:
      band:    1
      triggers: [_.range(225,256)]
    mid:
      band:    10
      triggers: [_.range(160,256)]
    high:
      band:    24
      triggers: [_.range(70,255)]

  # $scope.track    =
  #   file: "http://localhost:8000/tracks/playing_your_game.mp3"
  #   low:
  #     band:    0
  #     triggers: [_.range(235,256)]
  #   mid:
  #     band:    $scope.fft/4
  #     triggers: [_.range(150,256)]
  #   high:
  #     band:    23
  #     triggers: [_.range(90,255)]

  # $scope.track    =
  #   file: "http://localhost:8000/tracks/givein.mp3"
  #   low:
  #     band:    0
  #     triggers: [_.range(255,256), _.range(254, 255), _.range(250, 254)]
  #   mid:
  #     band:    $scope.fft/4
  #     triggers: [_.range(150,256)]
  #   high:
  #     band:    30
  #     triggers: [_.range(10,255)]

  # $scope.track    =
  #   file: "http://localhost:8000/tracks/intro.mp3"
  #   low:
  #     band:    2
  #     triggers: [_.range(240,256)]
  #   mid:
  #     band:    $scope.fft/4
  #     triggers: [_.range(150,256)]
  #   high:
  #     band:    27
  #     triggers: [_.range(10,255)]

  $scope.track    =
    file: "http://localhost:8000/tracks/coffee.mp3"
    low:
      band:    1
      triggers: [_.range(254,256)]
    mid:
      band:    $scope.fft/4
      triggers: [_.range(150,256)]
    high:
      band:    26
      triggers: [_.range(1,255)]


  # $scope.track    = "http://localhost:8000/tracks/natty_dread.mp3"
  # $scope.track    = "http://localhost:8000/tracks/coffee.mp3"
  # $scope.track    = "http://localhost:8000/tracks/safe_and_sound.mp3"
  # $scope.track    = "http://localhost:8000/tracks/juicy.mp3"

  $scope.rgb =
    r: 0
    g: 0
    b: 0
  $scope.d_rgb = $scope.rgb

  $scope.$watch( "rgb.r", (n,o)->
    $scope.set()
  )
  $scope.$watch( "rgb.g", (n,o)->
    $scope.set()
  )
  $scope.$watch( "rgb.b", (n,o)->
    $scope.set()
  )

  $scope.set= ->
    $http.get($scope.svc_url + "/set", params: $scope.rgb ).then (response) ->
      $scope.d_rgb = response.data
    $scope.done = true
    setTimeout $scope.poll, 1000

  $scope.demo= ->
    $http.get($scope.svc_url + "/otto", params: $scope.rgb )
    $scope.done = false
    setTimeout $scope.poll, 1000

  $scope.set_rgb= (r,g,b)->
    [$scope.rgb.r, $scope.rgb.g, $scope.rgb.b] = [r,g,b]
    $scope.set()

  $scope.off= ->
    $http.get($scope.svc_url + "/off", params: $scope.rgb ).then (response) ->
      $scope.d_rgb = response.data
      $scope.rgb   = $scope.d_rgb
    $scope.done = true

  $scope.poll= ->
    $http.get($scope.svc_url + '/state').then (response) ->
      $scope.d_rgb = response.data
      if !$scope.done
        setTimeout $scope.poll, 1000

  $scope.init= ->
    audioVisual    = document.getElementById('audio-visual')
    audio          = new Audio()
    audio.src      = $scope.track.file
    audio.controls = true
    audio.autoplay = $scope.playing
    audio.id       = 'a'

    audioVisual.appendChild(audio)

    audio.addEventListener( "play", ->
      $scope.playing = true
    )
    audio.addEventListener( "pause", ->
      $scope.playing = false
    )

    context = new webkitAudioContext()
    $scope.analyser = context.createAnalyser()
    $scope.analyser.fftSize = $scope.fft

    source = context.createMediaElementSource(audio)
    source.connect($scope.analyser)
    $scope.analyser.connect(context.destination)

    $scope.setup_viz()
    $scope.update()
    null

  $scope.setup_viz= ->
    visualization = $("#visualization")
    barSpacingPercent = 100 / $scope.analyser.frequencyBinCount
    for i in [0..$scope.analyser.frequencyBinCount] by 1
      div = $("<div/>").css("left", i * barSpacingPercent + "%")
                       .css("background-color", "#3BAFDA")
                       .css("width"           , "40px")
                       .css("margin-right"    , "1px")
                       .css("float"           , "left")
                       .appendTo(visualization)
      $("<span>#{i}</span>").appendTo(div)
    $scope.bars = $("#visualization > div")

  $scope.update= ->
    return if !$scope.playing

    requestAnimationFrame($scope.update)
    data  = new Uint8Array($scope.analyser.frequencyBinCount)
    $scope.analyser.getByteFrequencyData(data)

    rgb = [0,0,0]
    for band, i in ["low", "mid", "high"]
      for range, j in $scope.track[band].triggers
        if _.contains( range, data[$scope.track[band].band] )
          rgb[i] = 255-i*50
          break

    if data[$scope.track.low.band] > 240
      console.log "#{data[$scope.track.low.band]} -- #{data[$scope.track.mid.band]} -- #{data[$scope.track.high.band]}"
      #console.log rgb
    $scope.set_rgb( rgb[0], rgb[1], rgb[2] )

    $scope.bars.each( (index, bar)->
      bar.style.height = data[index] + 'px'
    )
