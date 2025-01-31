//record vector cutting file generator 
//by Amanda Ghassaei
//May 2013
//http://www.instructables.com/id/Laser-Cut-Record/
//detailed instructions for using this code at http://www.instructables.com/id/Laser-Cut-Record/step7

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
*/

/* edited by Tristan Rodman in March 2017 for use in generating plates for a letterpress */

import processing.pdf.*;

//parameters
String filename = "terminus_newEQ.txt";//generate a txt file of your waveform using python wav to txt, and copy the file name here
float rpm = 78.0;//33.3,45,78
float samplingRate = 44100;//sampling rate of incoming audio
float dpi = 1200;//dpi of cutter
int cutterWidth = 7;//width of laser cutter bed in inches
int cutterHeight = 7;//height of laser cutter bed in inches
float amplitude = 15;//in pixels
float spacing = 5;//space between grooves (in pixels)
float minDist = .5;//min pixel spacing between points in vector path (to prevent cutter from stalling)
float thetaIter = 20000;//how many values of theta per cycle
float diameter = 7;//diameter of record in inches
float innerHole = 0.286;//diameter of center hole in inches
float innerRad = 1.75;//radius of innermost groove in inches
float outerRad = 3.375;//radius of outermost groove in inches: 5.75 for 12", 3.375 for 7"
boolean cutlines = true;//cut the inner and outer perimeters
boolean drawBoundingBox = false;//draw a rect around the whole thing (helps with alignment)
int numGroovesPerFile = 200;//many lasers will choke if you send them all the data at once, this number spits the cutting path into several files taht can be sent to the laser cutter in series, decrease this number to lower the amount of data on each section



void setup(){
  
  //constants
  float secPerMin = 60;
  int scaleNum = 72;//scale factor of vectors (default 72 dpi)
  
  //storage variables
  float radCalc;
  float xVal;
  float yVal;
  float theta;//angular variable
  float radius;
  float xValLast = 0.0;
  float yValLast = 0.0;
  
  //scale pixel distances
  amplitude =  amplitude/dpi*scaleNum;
  minDist =  minDist/dpi*scaleNum;
  spacing =  spacing/dpi*scaleNum;
  
  float[] songData = processAudioData();
  
  //change extension of file name
  int dotPos = filename.lastIndexOf(".");
  if (dotPos > 0)
    filename = filename.substring(0, dotPos);
  
  //open pdf file
  size(522,522);
  int section = 1;
  beginRecord(PDF, filename + "0.pdf");//save as PDF
  background(255);//white background
  noFill();//don't fill loops
  strokeWeight(0.25);//plate width
  
  //init variables
  float incrNum = TWO_PI/thetaIter;//calculcate angular inrementation amount
  float radIncrNum = (2*amplitude+spacing)/thetaIter;//radial incrementation amount
  radius = outerRad*scaleNum;//calculate outermost radius (at 5.75")
  
  stroke(0,0,0);//black
  beginShape();//start vecotr path
  
  //draw silent outer groove
  for(theta=0;theta<TWO_PI;theta+=incrNum){//for theta between 0 and 2pi
    //calculate new point
    radCalc = radius;
    xVal = 3.625*scaleNum+radCalc*cos(theta);
    yVal = 3.625*scaleNum-radCalc*sin(theta);
    if(((xValLast-xVal)*(xValLast-xVal)+(yValLast-yVal)*(yValLast-yVal))>(minDist*minDist)){
      vertex(xVal,yVal);
      //store last coordinates in vector path
      xValLast = xVal;
      yValLast = yVal;
    }
    radius -= radIncrNum;//decreasing radius forms spiral
  }
  
  int numGrooves = 1;
  int index = 0;
  int indexIncr = int((samplingRate*secPerMin/rpm)/thetaIter);
  while(radius>innerRad*scaleNum && index < songData.length-thetaIter*indexIncr){
    for(theta=0;theta<TWO_PI;theta+=incrNum){//for theta between 0 and 2pi
      //calculate new point
      radCalc = radius+songData[index];
      index+=indexIncr;//go to next spot in audio data
      xVal = 3.625*scaleNum+radCalc*cos(theta);
      yVal = 3.625*scaleNum-radCalc*sin(theta);
      if(((xValLast-xVal)*(xValLast-xVal)+(yValLast-yVal)*(yValLast-yVal))>(minDist*minDist)){
        vertex(xVal,yVal);
        //store last coordinates in vector path
        xValLast = xVal;
        yValLast = yVal;
      }
      radius -= radIncrNum;//decreasing radius forms spiral
    }
    numGrooves++;
    if (numGrooves%numGroovesPerFile==0){
      endShape();
      if (drawBoundingBox) rect(0,0,cutterWidth*scaleNum,cutterHeight*scaleNum);
      endRecord();
      String fileNumber = str(numGrooves/numGroovesPerFile);
      beginRecord(PDF, filename + fileNumber + ".pdf");//save as PDF
      noFill();//don't fill loops
      strokeWeight(0.25);//hairline width
      stroke(0,0,0);
      beginShape();
      vertex(xValLast,yValLast);
    }
    println(numGrooves);
  }
  
  //draw silent inner locked groove
  for(theta=0;theta<TWO_PI;theta+=incrNum){//for theta between 0 and 2pi
    //calculate new point
    radCalc = radius;
    xVal = 3.625*scaleNum+radCalc*cos(theta);
    yVal = 3.625*scaleNum-radCalc*sin(theta);
    if(((xValLast-xVal)*(xValLast-xVal)+(yValLast-yVal)*(yValLast-yVal))>(minDist*minDist)){
      vertex(xVal,yVal);
      //store last coordinates in vector path
      xValLast = xVal;
      yValLast = yVal;
    }
    radius -= radIncrNum;//decreasing radius forms spiral
  }
  for(theta=0;theta<TWO_PI;theta+=incrNum){//for theta between 0 and 2pi
    //calculate new point
    xVal = 3.625*scaleNum+radius*cos(theta);
    yVal = 3.625*scaleNum-radius*sin(theta);
    if(((xValLast-xVal)*(xValLast-xVal)+(yValLast-yVal)*(yValLast-yVal))>(minDist*minDist)){
      vertex(xVal,yVal);
      //store last coordinates in vector path
      xValLast = xVal;
      yValLast = yVal;
    }
  }
  
  endShape();
  
  if (cutlines){
    //draw cut lines (100 units = 1")
    stroke(0);//draw in black
    ellipse(3.625*scaleNum,3.625*scaleNum,innerHole*scaleNum,innerHole*scaleNum);//0.286" center hole
    ellipse(3.625*scaleNum,3.625*scaleNum,diameter*scaleNum,diameter*scaleNum);//12" diameter outer edge
  }
  
  endRecord();
  exit();
  
  //tell me when it's over
  println("Finished.");
  
}

float[] processAudioData(){
  
  //get data out of txt file
  String rawData[] = loadStrings(filename);
  String rawDataString = rawData[0];
  float audioData[] = float(split(rawDataString,','));//separated by commas
  
  //normalize audio data to given bitdepth
  //first find max val
  float maxval = 0;
  for(int i=0;i<audioData.length;i++){
    if (abs(audioData[i])>maxval){
      maxval = abs(audioData[i]);
    }
  }
  //normalize amplitude to max val
  for(int i=0;i<audioData.length;i++){
    audioData[i]*=amplitude/maxval;
  }
  
  return audioData;
}