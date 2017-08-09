function [ out ] = VideoAnalysis ( in )
%% Title Block
% 
% VideoAnalysis.m
%
% Author: Daniel O'Rourke
%
% This function reads in image or video data and finds
% red and green spots, and tracks their movement.
%
%
%
%% Variables

green_limit = 245;
red_limit   = 245;
dark_limit  = 230;

circle_size = [1,5];


  
  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file or directory', 's');
  end
  
  %Determine if file or directory
  [~,b]=strtok(in,'.');
  
  if isempty(b)
    %input might be a directory
    if isdir(in)
      %input is a directory
      
    else
      %error, invalid directory
    end
  else
    %input is a filename
    
    v = VideoReader(in);
    point1=[];
    point2=[];
    framenumber=0;
    while hasFrame(v)
        framenumber=framenumber+1;
        sprintf('Processing frame %d',framenumber);
        %get frame
        img = readFrame(v);
        %split image
        r=img(:,:,1);g=img(:,:,2);b=img(:,:,3);
        %find green
        gmask = g>green_limit & r<dark_limit & b<dark_limit;
        %find red
        rmask = g<dark_limit & r>red_limit & b<dark_limit;
        %set red and green to white
        g(gmask)=254;r(gmask)=254;b(gmask)=254;
        g(rmask)=254;r(rmask)=254;b(rmask)=254;
        %sum red and green
        lmask=gmask+rmask;
        %make all not red or green black
        g(~lmask)=0;r(~lmask)=0;b(~lmask)=0;
        newimg=cat(3,r,g,b);
        [centers,~,~]=imfindcircles(newimg,circle_size);
        if isempty(centers)
          %error, no points found
        else
          [a,~]=size(centers);
          switch a
            case 1
              %error only 1 point found
            case 2
              point1=[point1;centers(1,:)]; %#ok<*AGROW>
              point2=[point2;centers(2,:)]; % Cannot preallocate video size
            
          end
        end
    end
  
  end
out={point1,point2};
end