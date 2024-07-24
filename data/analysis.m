clear;
close all hidden;

KiB = 2^10; % 1024 Bytes
ms_per_sec = 10^3; % 1000 ms/s
frequency = 40 * 10^6; % 40 MHz

copytotile = readtable("copytotile.csv");
copytoarm = readtable("copytoarm.csv");
processchunk = readtable("processchunk.csv");

joinedall = outerjoin(copytotile, copytoarm, "Keys", {'ID', 'X', 'Y', 'BPP', 'F'}, "MergeKeys", true);
joinedall = outerjoin(joinedall, processchunk, "Keys", {'ID', 'X', 'Y', 'BPP', 'F'}, "MergeKeys", true);

tile0 = joinedall(joinedall.TILE==0, :);
tile1 = joinedall(joinedall.TILE==1, :);
tile2 = joinedall(joinedall.TILE==2, :);

tileutility = [size(tile0, 1), size(tile1, 1), size(tile2, 1)];

figure();
bar(tileutility);
title("Utility of each tile");
xticklabels([0 1 2]);

executiontimes = joinedall.DBTM + joinedall.DBTM_copytotile + joinedall.DBTM_copytoarm;
sum_executiontimes = accumarray(joinedall.F, executiontimes);
sum_nbytes = accumarray(joinedall.F, joinedall.NBYTES);

[~, indices] = unique(joinedall.F);
unique_joinedall = joinedall(indices, :);
unique_sorted_joinedall = sortrows(unique_joinedall, "F");
image_bytes = unique_sorted_joinedall.IMGBYTES;

% add total bytes of file and rerun and recalculate

figure();
qqplot(sum_executiontimes ./ frequency .* ms_per_sec, image_bytes ./ KiB);
xlabel("ET in ms");
ylabel("Size in KiB");

close all;