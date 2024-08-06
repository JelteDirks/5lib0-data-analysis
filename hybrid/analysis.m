clear;
close all hidden;

KiB = 2^10; % 1024 Bytes
frequency = 10^6 * 40; % 40 MHz
ms_per_s = 10^3; % 1.000 ms/s
us_per_s = 10^6; % 1.000.000 us/s
cycles_per_schedule = 1000000; % cycles per schedule
cycles_per_part0 = 5000;
cycles_per_cswitch = 2000;

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

sum_all_times = [sum_grey_times ; sum_color_times];
table_headers = {'ET', 'ID', 'IMGSIZE', 'LATENCY'};
sorted_all_times = array2table(sortrows(sum_all_times, 2), "VariableNames", table_headers);

sorted_all_times.ID = sorted_all_times.ID + 1;

save("hybrid_times", "sorted_all_times");

latency_executiontime_diff = sorted_all_times.LATENCY - sorted_all_times.ET;

figure();
subplot(1, 3, 1);
scatter(sorted_all_times.IMGSIZE ./ KiB, sorted_all_times.LATENCY ./ frequency .* ms_per_s);
ylabel("Reponse time (ms)");
xlabel("Image size (KiB)");
title("Latency");
ylim([0 6000]);

subplot(1, 3, 2);
scatter(sorted_all_times.IMGSIZE ./ KiB, sorted_all_times.ET ./ frequency .* ms_per_s);
ylabel("Execution time (ms)");
xlabel("Image size (KiB)");
title("Execution Time");
ylim([0 6000]);

subplot(1, 3, 3);
scatter(sorted_all_times.IMGSIZE ./ KiB, latency_executiontime_diff ./ frequency .* ms_per_s);
xlabel("Image size (KiB)");
ylabel("Latency - Execution time (ms)");
ylim([0 400])
title("Difference");

total_bytes_processed = sum(sorted_all_times.IMGSIZE);
total_time_processing = sum(sorted_all_times.LATENCY);
throughput_kib_per_s = total_bytes_processed / KiB / (total_time_processing / frequency);

disp("Throughput: " + throughput_kib_per_s + " KiB/s");
disp("Average latency: " + mean(sorted_all_times.LATENCY) / frequency + " s");
disp("Average latency per byte: " + mean(sorted_all_times.LATENCY ./ sorted_all_times.IMGSIZE) / frequency * ms_per_s + " ms");

capped_latency = sorted_all_times.LATENCY;
capped_latency(capped_latency <= cycles_per_schedule) = 0;
context_switches = capped_latency ./ cycles_per_schedule;
context_switch_cycles = floor(context_switches) .* (cycles_per_part0 + cycles_per_cswitch);
context_switch_time = context_switch_cycles ./ frequency .* ms_per_s;
mean_cswitch_time = mean(context_switch_time);

disp("Average context switch time: " + mean_cswitch_time + " ms");

figure();
qqplot(context_switch_time, image_sizes_kibs);

figure();
boxplot(sorted_all_times.LATENCY ./ frequency .* ms_per_s);
ylabel("Latency (ms)");
title("Latency of all images");
xticklabels("Hybrid");

close all;