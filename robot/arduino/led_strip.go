package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"github.com/hybridgroup/gobot"
	"github.com/hybridgroup/gobot/api"
	"github.com/hybridgroup/gobot/platforms/firmata"
)

const (
	Pin_red   = "3"
	Pin_green = "5"
	Pin_blue  = "6"
  Device    = "/dev/tty.usbmodem1421"
)

type RGB struct {
	red   uint8
	green uint8
	blue  uint8
}
func (r *RGB) Randomize() {
	color := r.randInt(0, 3)
	value := r.randInt(0, 255)

	switch color {
	case 0:
		r.red = value
	case 1:
		r.green = value
	case 2:
		r.blue = value
	}
	fmt.Printf("%v\n", r)
}
func (r *RGB) randInt(min uint8, max uint8) uint8 {
	return min + uint8(rand.Intn(int(max-min)))
}
func (r *RGB) ToJSON() []byte {
	state := make(map[string]uint8)
	state["r"] = r.red
	state["g"] = r.green
	state["b"] = r.blue

	data, _ := json.Marshal(state)
	return data
}
func (r *RGB) Update(red, green, blue int) {
	r.red, r.green, r.blue = uint8(red), uint8(green), uint8(blue)
}


var rgb = RGB{0, 0, 0}
var done = false

func main() {
	gbot    := gobot.NewGobot()
	adaptor := firmata.NewFirmataAdaptor("myFirmata", Device)

	api := api.NewAPI(gbot)
	api.Port = "4500"
	api.Start()

	robot := gbot.AddRobot(gobot.NewRobot("crib"))
	robot.AddConnection(adaptor)

	rand.Seed(time.Now().UTC().UnixNano())

  // APIs - definition
	api.AddHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET,POST")
	})
	api.Get("/state", func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Content-Type", "application/json; charset=utf-8")
		res.Write(rgb.ToJSON())
	})
	api.Get("/set", func(res http.ResponseWriter, req *http.Request) {
		r, _ := strconv.Atoi(req.URL.Query()["r"][0])
		g, _ := strconv.Atoi(req.URL.Query()["g"][0])
		b, _ := strconv.Atoi(req.URL.Query()["b"][0])

		rgb.Update(r, g, b)
		set(adaptor, rgb)

		res.Header().Set("Content-Type", "application/json; charset=utf-8")
		res.Write(rgb.ToJSON())
	})
	api.Get("/off", func(res http.ResponseWriter, req *http.Request) {
		done = true
		rgb.Update(0, 0, 0)
		set(adaptor, rgb)

		res.Header().Set("Content-Type", "application/json; charset=utf-8")
		res.Write(rgb.ToJSON())
	})
	api.Get("/otto", func(res http.ResponseWriter, req *http.Request) {
		c := time.Tick(1000 * time.Millisecond)
		done = false
		for !done {
			<-c
			go demo(adaptor)
		}
		res.Header().Set("Content-Type", "application/json; charset=utf-8")
		res.Write(rgb.ToJSON())
	})

	gbot.Start()
}

func demo(adaptor *firmata.FirmataAdaptor) {
	rgb.Randomize()
	set(adaptor, rgb)
}

func set(adaptor *firmata.FirmataAdaptor, rgb RGB) {
	adaptor.PwmWrite(Pin_red, rgb.red)
	adaptor.PwmWrite(Pin_green, rgb.green)
	adaptor.PwmWrite(Pin_blue, rgb.blue)
}
