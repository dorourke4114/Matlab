function [ out ] = testimage ( in )

  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file or directory:\n', 's');
  end
if isstring(in)
    [~,ext]=strtok(in,'.');
    if ~isempty(ext)
        if strcmpi(ext,'.mp4')
            v=VideoReader(in);
            img=readFrame(v);
        else
            
        end
    else
        [img]=imread(in);
    end
else
    img=in;
end




r=img(:,:,1);
g=img(:,:,2);
b=img(:,:,3);

mask = r>g.*1.5 & r>b.*1.5 & r>100;

g(mask)=254;
r(mask)=254;
b(mask)=254;
g1=g;
r1=r;
b1=b;
g1(~mask)=g(~mask).*0.5;
r1(~mask)=r(~mask).*0.5;
b1(~mask)=b(~mask).*0.5;
g(~mask)=0;
r(~mask)=0;
b(~mask)=0;
img = cat(3,r,g,b);

[centers,radii,metric]=imfindcircles(img,[40,90])

img1= cat(3,r1,g1,b1);

image(img)

out=[];
end