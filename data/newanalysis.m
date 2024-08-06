clear;

elapsed_time_s = 2 * 60 + 16.667;
KiB = 2^10; % 1024 Bytes
frequency = 10^6 * 40; % 40 MHz
ms_per_s = 10^3;
ns_per_ms = 10^6;

latencytbl = readtable("datalatency.csv");

N = size(latencytbl, 1);
latencytbl.LATENCYMS = (latencytbl.SEC .* ms_per_s) + (latencytbl.NSEC ./ ns_per_ms);
latencytbl.NBYTES = latencytbl.X .* latencytbl.Y .* (latencytbl.BPP / 8);
total_bytes = sum(latencytbl.NBYTES);
kib_per_s = (total_bytes / KiB) / (elapsed_time_s);

CPU_time = sum(latencytbl.LATENCYMS) / ms_per_s;

disp("===DATA PARALLEL ===")
disp("Elapsed time (wall clock): " + elapsed_time_s + " s");
disp("Processing time: " + CPU_time + " s");
disp("Parallel utilization: " + CPU_time / elapsed_time_s + " x");
disp("Bytes processed: " + total_bytes + " B");
disp("Throughput: " + kib_per_s + " KiB/s");
disp("Average latency: " + elapsed_time_s / N + " s/image");
disp("Average latency per byte: " + (elapsed_time_s * ms_per_s) / (total_bytes) + " ms/B");
disp("Max latency per iamge: " + max(latencytbl.LATENCYMS) / ms_per_s + " s/image");
disp("Median latency per image: " + median(latencytbl.LATENCYMS) / ms_per_s + " s/image");
disp("Mean image size: " + mean(latencytbl.NBYTES) / KiB + " KiB");
disp("Median image size: " + median(latencytbl.NBYTES) / KiB + "KiB")
disp("======");

figure();
boxplot(latencytbl.NBYTES ./ KiB);
ylabel("Image size (KiB)");
xticklabels("Data");