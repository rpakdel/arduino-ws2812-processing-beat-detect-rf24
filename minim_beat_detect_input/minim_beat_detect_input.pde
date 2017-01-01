/**
  * This sketch demonstrates how to use the BeatDetect object song SOUND_ENERGY mode.<br />
  * You must call <code>detect</code> every frame and then you can use <code>isOnset</code>
  * to track the beat of the music.
  * <p>
  * This sketch plays an entire song, so it may be a little slow to load.
  * <p>
  * For more information about Minim and additional features, 
  * visit http://code.compartmental.net/minim/
  */
  
import ddf.minim.*;
import ddf.minim.analysis.*;

import processing.serial.*;

Minim minim;
BeatDetect beat;
AudioInput in;
AudioPlayer song;

int numBands = 16;
float[] eRadius;
color[] displayColors;
color[] beatColors;
float levelScale = 1.0;
float levelIncrement = 0.1;
float minLevel = 1.0;

String serialPortName = "COM7";
Serial serialPort = null;
int SERIAL_DATA_RATE = 115200;


void setup()
{
  
  serialPort = new Serial(this, serialPortName, SERIAL_DATA_RATE);
  
  eRadius = new float[numBands];
  displayColors = new color[numBands];
  beatColors = new color[numBands];
  for(int i = 0; i < numBands; ++i)
  {
    eRadius[i] = 20;
    displayColors[i] = color(0, 0, 0);
  }
  
  size(1000, 400, P3D);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO);  
  beat = new BeatDetect(in.bufferSize(), in.sampleRate());
  beat.setSensitivity(100);  
  
  //song = minim.loadFile("marcus_kellis_theme.mp3", 1024);
  //song.play();
  
  // a beat detection object song SOUND_ENERGY mode with a sensitivity of 10 milliseconds
  //beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  
  ellipseMode(RADIUS);  
  stroke(255, 255, 255);
  background(0);
}

color pixelOnColor = color(25, 25, 25, 255);
color pixelOffColor = color(0, 0, 0, 255);

boolean pixelsOn = true;
void togglePixels(int d)
{
  color pixelsColor;
  if (pixelsOn)
  {
    pixelsOn = false;
    pixelsColor = pixelOnColor;
  }
  else
  {
    pixelsOn = true;
    pixelsColor = pixelOffColor;
  }
  
  background(pixelsColor);
  for(int i = 0; i < 17; i++)
  {
    serialWritePixel(i, pixelsColor);
  }
  delay(d);
}

void toggleOnePixel(int pixelIndex)
{
  for(int i = 0; i < 17; i++)
  {
    if (i == pixelIndex)
    {
      serialWritePixel(i, pixelOnColor);
    }
    else
    {
      serialWritePixel(i, pixelOffColor);
    }
  }
}

void clockPixels(int d)
{
  for(int i = 0; i < 16; i++)
  {
    toggleOnePixel(i);
    //delay(d);
  }
}

int p = 0;

void draw()
{ 
  background(0);
  //clockPixels(1);
  
  
  detectBeat();
  
}

void detectBeat()
{
  if (keyPressed)
  {
     if (key == '=')
     {
       levelScale += levelIncrement;
       print("Level scale: ");
       println(levelScale);
     }
     else if (key == '-')
     {
       levelScale -= levelIncrement;
       if (levelScale <= 0.0001)
       {
         levelScale = 0.0001;         
       }
       print("Level scale: ");
       println(levelScale);
     }
     else if (key == '.')
     {
       minLevel += levelIncrement;
       print("Min level: ");
       println(minLevel);
     }
     else if (key == ',')
     {
       minLevel -= levelIncrement;
       print("Min level: ");
       println(minLevel);
     }
  }
  
  
  beat.detect(in.mix);
  int size = beat.detectSize();
  //println(size);
  float w = (size * 1.0) / (numBands * 1.0);
  
  float level = abs(in.mix.level()) * levelScale * 100 * 2;
  
  for (int bandIndex = 0; bandIndex < numBands; bandIndex++)
  {        
    
    
    int band = (int)(w * (bandIndex + 1) - w / 2.0);    
    if (beat.isOnset(band) && level >= minLevel)
    {            
      eRadius[bandIndex] = level;      
      
      int red = 0;
      int green =  0;
      int blue = 0;
      
      if (beat.isKick())
      {
        red = 255;
      }
      else if (beat.isSnare())
      {
        green = 255;
      }
      else if (beat.isHat())
      {
        blue = 255;
      }
      else
      {
        red = green = blue = 255;
      }
           
      displayColors[bandIndex] = color(red, green, blue, 200);      
      beatColors[bandIndex] = color(red, green, blue, 255);      
    }
    
    drawCircle(bandIndex, numBands, band, level, eRadius[bandIndex]);    
    serialWritePixel(bandIndex, beatColors[bandIndex]);
            
    
    
    // reduce the values
    eRadius[bandIndex] *= 0.8;    
    float scaleValue = 0.8;
    displayColors[bandIndex] = scaleColor(displayColors[bandIndex], scaleValue);
    beatColors[bandIndex] = scaleColor(displayColors[bandIndex], scaleValue);
  }
}

void drawCircle(int bandIndex, int numBands, int band, float level, float radius)
{
  fill(displayColors[bandIndex]);
  float x = width * (bandIndex + 1)/(numBands + 1);
  float y = height / 2.0;
  ellipse(x, y, radius, radius);
  
  fill(color(255, 255, 255, 255));
  
  float stry = height - 3 * 20;
  if (bandIndex == 0)
  {
    text("Index", 10, stry);
  }
  text(str(bandIndex), x, stry);
  stry += 20;
  if (bandIndex == 0)
  {
    text("Band", 10, stry);
  }
  text(str(band), x, stry);
  stry += 20;
  if (bandIndex == 0)
  {
    text("Level", 10, stry);
  }
  text(nf(level,3,2), x, stry);
}

color scaleColor(color c, float scale)
{  
  return color((int)(red(c) * scale), (int)(green(c) * scale), (int)(blue(c) * scale)); 
}

void writeValuesToSerial(color[] beats)
{
  for(int index = 0; index <= numBands; index++)
  {
    color c = beats[index];
    serialWritePixel(index, c);
  }
}

byte[] getSerialWritePixelBytes(int pixelIndex, color c)
{
  byte[] bytes = new byte[6];
  fillSerialWritePixelBytes(bytes, pixelIndex, c);
  return bytes;
}

void fillSerialWritePixelBytes(byte[] bytes, int pixelIndex, color c)
{
  bytes[0] = '#';
  bytes[1] = (byte)pixelIndex;
  
  bytes[2] = (byte) ((c >> 24) & 0xff);
  bytes[3] = (byte) ((c >> 16) & 0xff);
  bytes[4] = (byte) ((c >> 8) & 0xff);
  bytes[5] = (byte) (c & 0xff);
}

byte[] pixelBytes = new byte[6];
void serialWritePixel(int pixelIndex, color c)
{
  //print(pixelIndex);
  //print("|");
  //println(hex(c));
   if (serialPort != null)
   {
     fillSerialWritePixelBytes(pixelBytes, pixelIndex, c);
     serialPort.write(pixelBytes);     
     
     // band-aid fix for bug where 1 pixel doesn't turn on
     if (pixelIndex == (numBands - 1))
     {
       fillSerialWritePixelBytes(pixelBytes, numBands, c);
       serialPort.write(pixelBytes);
     }
   }   
}

void serialWriteByte(int x)
{
  if (serialPort != null)
  {
    serialPort.write(x);
  }
}



void serialWriteColor(color c)
{
  //print(':');
  int i0 = (c >> 24) & 0xff;
  //print(binary(i0, 8));
  serialWriteByte(i0);
  
  
  //print('|');
  int i1 = (c >> 16) & 0xff;
  //print(binary(i1, 8));
  serialWriteByte(i1);
  
  //print('|');
  int i2 = (c >> 8) & 0xff;
  //print(binary(i2, 8));
  serialWriteByte(i2);
  
  //print('|');
  int i3 = c & 0xff;
  //println(binary(i3, 8));
  serialWriteByte(i3);
  
  
}