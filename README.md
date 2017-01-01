Beat detection via Processing and light show via WS2812 ring (directly connect via Serial)

# Hardware

* WS2812 16 pixel ring
* 2x NRF2401 for transmission

# Software

* Beat detection is done on PC via Processing minim module
* Beats and colors are passed to Arduino via Serial encoded bits (slow and really hard to do. Not recommended)