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
% SR-523 orientation and translation error
% SR-522 delay
%
%% Variables

red_limit   = 255;
dark_limit  = 230;

circle_size = [5,50];


%% Input Sterilization

  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file:\n', 's');
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
    total_frames=ceil(v.Duration.*v.FrameRate);
    points=cell(total_frames,2);
    framenumber=0;
    
    while hasFrame(v)
        framenumber=framenumber+1;
        fprintf('Processing frame %d of %d\n',framenumber, total_frames);
        %get frame
        img = readFrame(v);
        
        
        %% Do the image processing
        
        point = findcirclepoints (img, red_limit, dark_limit, circle_size);
        
        points(framenumber,1)=point(1);
        points(framenumber,2)=point(2);
        
    end
  
  end
out=[point];
end

%% Sub functions

%% Find Circle Points
function point = findcirclepoints (img, red_limit, dark_limit, circle_size)
% Find circle points 


 %split image
        r=img(:,:,1);g=img(:,:,2);b=img(:,:,3);
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
        imshow(newimg);
        [centers,~,~]=imfindcircles(newimg,circle_size);
        if isempty(centers)
          %error, no points found
          point={'MISSING'};
        else
          [a,~]=size(centers);
          switch a
            case 1
              %error only 1 point found
              point={centers(1,:),'MISSING'};
            case 2
              point={centers(1,:),centers(2,:)};
          end
        end

end