clear;
close all hidden;

KiB = 2^10; % 1024 Bytes
ms_per_s = 10^3; % 1000 ms/s
ns_per_ms = 10^6;
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

executiontimes = joinedall.DBTM + joinedall.DBTM_copytotile + joinedall.DBTM_copytoarm;
sum_executiontimes = accumarray(joinedall.F, executiontimes);

[~, indices] = unique(joinedall.F);
unique_joinedall = joinedall(indices, :);
unique_sorted_joinedall = sortrows(unique_joinedall, "F");
image_bytes = unique_sorted_joinedall.IMGBYTES;
image_bytes_kib = image_bytes ./ KiB;

bytes_processed_per_image = [accumarray(processchunk.F, processchunk.NBYTES), image_bytes];
bppi_kib = bytes_processed_per_image ./ KiB;
bppi_diff = [(bppi_kib(:, 1) - bppi_kib(:, 2)) , bppi_kib(: ,2)];

selection = ones(34, 1);
selection([31, 32]) = 0; % Remove duplicate images from earlier
latencystats = readtable("latencystats.csv");
latencystats.NBYTES = (latencystats.BPP ./ 8) .* latencystats.X .* latencystats.Y;
latencystats.ET = sum_executiontimes(selection == 1);
latencystats.LATENCYMS = (latencystats.SEC .* ms_per_s) + (latencystats.NSEC ./ ns_per_ms);
latencystats.ETMS = latencystats.ET ./ frequency .* ms_per_s;
latencystats.DIFF = latencystats.LATENCYMS - latencystats.ETMS;

figure();
bar(tileutility);
title("Utility of each tile");
xticklabels([0 1 2]);
xlabel("Tile number")

figure();
subplot(1,2,1);
qqplot(image_bytes_kib, sum_executiontimes ./ frequency .* ms_per_s);
ylabel("Execution time (ms)");
xlabel("Image size (KiB)");
xlim([0 600]);

et_per_byte = sum_executiontimes ./ image_bytes;

subplot(1,2,2);
qqplot(image_bytes_kib, et_per_byte);
xlim([0 600]);
ylabel("Execution time (cycles per byte)");
xlabel("Image size (KiB)");

figure();
scatter(bppi_diff(:, 2), bppi_diff(:, 1));
xlabel("Image size (KiB)");
ylabel("Wasted bytes (KiB)")

throughput = sum(image_bytes_kib) / (sum(executiontimes) / frequency);
processed_bytes = joinedall.NBYTES_copytotile;
throughput_processed = (sum(processed_bytes) / KiB) / (sum(executiontimes) / frequency);
disp("Throughput in terms of input image size: " + throughput + " KiB/s");
disp("Throughput in terms of total bytes processed: " + throughput_processed + " KiB/s");

precentage_wasted = 1 - (throughput / throughput_processed);
disp("Percentage wasted: " + (precentage_wasted * 100));

tileutilpercentage = tileutility ./ sum(tileutility);
disp(tileutilpercentage);

figure();
qqplot(bppi_diff(:,1), bppi_diff(:,2));

close all;