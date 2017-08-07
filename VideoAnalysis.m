function [ out ] = VideoAnalysis ( in )
  
  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file or directory', 's');
  end
  
  %Determine if file or directory
  [filename,b]=strtok(in,'.');
  
  if isempty(b)
    %input is a directory
    
  elseif or ( strcmp(b,'.mts') , strcmp(b,'.mp4') )
    %input is a video filename
    
    v = VideoReader(in);
    while hasFrame(v)
        video = readFrame(v);
    end
  
  elseif or ( strcmp(b,'.png') , strcmp(b,'.jpg') )
      %input is a image filename
    
  end
  
end