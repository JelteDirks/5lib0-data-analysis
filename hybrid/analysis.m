clear;

KiB = 2^10; % 1024 Bytes
frequency = 10^6 * 40; % 40 MHz
ms_per_s = 10^3; % 1.000 ms/s
us_per_s = 10^6; % 1.000.000 us/s

tile0tokencopy = readtable("a.csv");
tile0convolution = readtable("b.csv");
tile0spacecopy = readtable("c.csv");

tile0joined = outerjoin(tile0tokencopy, tile0convolution, "Keys", "F", "MergeKeys", true);
tile0joined = outerjoin(tile0joined, tile0spacecopy, "Keys", "F", "MergeKeys", true);

tile1tokencopy = readtable("d.csv");
tile1greyconv = readtable("e.csv");
tile1spacecopy = readtable("f.csv");

tile1joined = outerjoin(tile1tokencopy, tile1greyconv, "Keys", "F", "MergeKeys", true);
tile1joined = outerjoin(tile1joined, tile1spacecopy, "Keys", "F", "MergeKeys", true);

tile2copysobeloverlay = readtable("g.csv");
tile2copyresult = readtable("h.csv");

tile2joined = outerjoin(tile2copysobeloverlay, tile2copyresult, "Keys", "F", "MergeKeys", true);

colorjoin = join(tile1joined, tile2joined, "Keys", "F");
greyjoin = join(tile0joined, tile2joined, "Keys", "F");

latencytbl = readtable("latency.csv");
response_times = latencytbl.TDIFF;
response_times_msec = (response_times ./ frequency) .* ms_per_s;
avg_response_time = mean(response_times);
image_sizes_kibs = latencytbl.NBITS ./ (KiB * 8);
response_times_per_byte = latencytbl.TDIFF ./ (latencytbl.NBITS .* 8);
avg_response_time_per_byte = mean(response_times_per_byte);

latencyjoingrey = outerjoin(latencytbl, greyjoin, "Keys", {'X', 'Y', 'BPP'}, "MergeKeys", true);
greyall = latencyjoingrey(~isnan(latencyjoingrey.F), :);
sum_grey_times = zeros(size(greyjoin, 1), 4);
sum_grey_times(:, 1) = greyall.DBTM_tile0tokencopy + greyall.DBTM_tile0convolution + greyall.DBTM + greyall.DBTM_tile2copysobeloverlay + greyall.DBTM_tile2copyresult;
sum_grey_times(:, 2) = greyall.F;
sum_grey_times(:, 3) = greyall.NBYTES_tile0tokencopy;
sum_grey_times(:, 4) = greyall.TDIFF;

latencyjoincolor = outerjoin(latencytbl, colorjoin, "Keys", {'X', 'Y'}, "MergeKeys", true);
colorall = latencyjoincolor(~isnan(latencyjoincolor.F), :);
colorall = colorall(colorall.BPP == 24, :);
sum_color_times = zeros(size(colorjoin, 1), 4);
sum_color_times(:, 1) = colorall.DBTM + colorall.DBTM_tile1tokencopy + colorall.DBTM_tile1greyconv + colorall.DBTM_tile2copysobeloverlay + colorall.DBTM_tile2copyresult;
sum_color_times(:, 2) = colorall.F;
sum_color_times(:, 3) = colorall.NBYTES_tile1joined;
sum_color_times(:, 4) = colorall.TDIFF;

figure();
subplot(1,3,1);
qqplot(response_times_msec, image_sizes_kibs);
ylim([0, max(image_sizes_kibs) + 5]);
xlabel("Reponse time in milliseconds");
ylabel("Image size in KiB");
title("Latency All Images");

max_y = max(max(sum_grey_times(:, 3) ./ KiB));
max_y = max(max_y, max(sum_color_times(:, 3) ./ KiB)) + 5;

subplot(1,3,2);
qqplot(sum_grey_times(:, 1) ./ frequency .* ms_per_s, sum_grey_times(:, 3) ./ KiB);
ylim([0, max_y])
xlabel("Execution time in milliseconds");
ylabel("Image size in KiB");
title("ET Greyscale Images");

subplot(1,3,3);
qqplot(sum_color_times(:, 1) ./ frequency .* ms_per_s, sum_color_times(:, 3) ./ KiB);
ylim([0, max_y])
xlabel("Execution time in milliseconds");
ylabel("Image size in KiB");
title("ET Color Images");

disp("Maximum latency gs: " + max(sum_grey_times(:, 4)) / frequency * ms_per_s + " milliseconds");
disp("Maximum latency c: " + max(sum_color_times(:, 4)) / frequency * ms_per_s + " milliseconds");
disp("Maximum ET gs: " + max(sum_grey_times(:, 1)) / frequency * ms_per_s + " milliseconds");
disp("Maximum ET c: " + max(sum_color_times(:, 1)) / frequency * ms_per_s + " milliseconds");

latency_et_diff_color = sum_color_times(:, 4) - sum_color_times(:, 1);
latency_et_diff_grey = sum_grey_times(:, 4) - sum_grey_times(:, 1);

figure();
subplot(1,2,1);
scatter(latency_et_diff_grey ./ frequency .* ms_per_s, sum_grey_times(:, 4) ./ frequency .* ms_per_s);
xlabel("Difference with ET in milliseconds");
ylabel("Measured latency in milliseconds");
title("Greyscale Images");

subplot(1,2,2);
scatter(latency_et_diff_color ./ frequency .* ms_per_s, sum_color_times(:, 4) ./ frequency .* ms_per_s);
xlabel("Difference with ET in milliseconds");
ylabel("Measured latency in milliseconds");
title("Color Images");

throughput_grey = (sum_grey_times(:, 3) ./ KiB) ./ (sum_grey_times(:, 4) ./ frequency);
throughput_color = (sum_color_times(:, 3) ./ KiB) ./ (sum_color_times(:, 4) ./ frequency);
disp("Grey image throughput (KiB/sec) max:" + max(throughput_grey) + " min:" + min(throughput_grey) + " mean:" + mean(throughput_grey));
disp("Color image throughput (KiB/sec) max:" + max(throughput_color) + " min:" + min(throughput_color) + " mean:" + mean(throughput_color));
