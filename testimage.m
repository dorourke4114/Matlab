function [ out ] = testimage ( in )

if nargin < 1
  in = 'C:\Users\orourd3\Desktop\movement tracking\DSC00828.JPG';
end

[img]=imread(in);

r=img(:,:,1);
g=img(:,:,2);
b=img(:,:,3);

mask = and(g>245,r<230,b<230);

g(mask)=254;
r(mask)=0;
b(mask)=0;
g(!mask)=0;
r(!mask)=0;
b(!mask)=0;

img = cat(3,r,g,b);

image(img)

end