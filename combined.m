clear;
close all;

KiB = 2^10;
frequency = 10^6 * 40; 
ms_per_s = 10^3;
ns_per_ms = 10^6;

datalatency = readtable("data/datalatency.csv");
data_elapsed_time_s = 30.244; % 2 * 60 + 16.667;

hybridlatency = readtable("hybrid/hybridlatency.csv");
hybrid_elapsed_time_s = 16.920;

data_N = size(datalatency, 1);
datalatency.LATENCYMS = (datalatency.SEC .* ms_per_s) + (datalatency.NSEC ./ ns_per_ms);
datalatency.NBYTES = datalatency.X .* datalatency.Y .* (datalatency.BPP / 8);
data_total_bytes = sum(datalatency.NBYTES);
data_kib_per_s = (data_total_bytes / KiB) / (data_elapsed_time_s);

data_CPU_time = sum(datalatency.LATENCYMS) / ms_per_s;

disp("===DATA PARALLEL ===")
disp("Elapsed time (wall clock): " + data_elapsed_time_s + " s");
disp("Processing time: " + data_CPU_time + " s");
disp("Parallel utilization: " + data_CPU_time / data_elapsed_time_s + " x");
disp("Bytes processed: " + data_total_bytes + " B");
disp("Throughput: " + data_kib_per_s + " KiB/s");
disp("Average latency: " + data_elapsed_time_s / data_N + " s/image");
disp("Average latency per byte: " + (data_elapsed_time_s * ms_per_s) / (data_total_bytes) + " ms/B");
disp("Max latency per image: " + max(datalatency.LATENCYMS) / ms_per_s + " s/image");
disp("Median latency per image: " + median(datalatency.LATENCYMS) / ms_per_s + " s/image");
disp("Mean image size: " + mean(datalatency.NBYTES) / KiB + " KiB");
disp("Median image size: " + median(datalatency.NBYTES) / KiB + "KiB")
disp("======");

hybrid_N = size(hybridlatency, 1);
hybridlatency.LATENCYMS = (hybridlatency.SEC .* ms_per_s) + (hybridlatency.NSEC ./ ns_per_ms);
hybridlatency.NBYTES = hybridlatency.X .* hybridlatency.Y .* (hybridlatency.BPP / 8);
hybrid_total_bytes = sum(hybridlatency.NBYTES);
hybrid_kib_per_s = (hybrid_total_bytes / KiB) / (hybrid_elapsed_time_s);

hybrid_CPU_time = sum(hybridlatency.LATENCYMS) / ms_per_s;

disp("===HYBRID PARALLEL ===")
disp("Elapsed time (wall clock): " + hybrid_elapsed_time_s + " s");
disp("Processing time: " + hybrid_CPU_time + " s");
disp("Parallel utilization: " + hybrid_CPU_time / hybrid_elapsed_time_s + " x");
disp("Bytes processed: " + hybrid_total_bytes + " B");
disp("Throughput: " + hybrid_kib_per_s + " KiB/s");
disp("Average latency: " + hybrid_elapsed_time_s / hybrid_N + " s/image");
disp("Average latency per byte: " + (hybrid_elapsed_time_s * ms_per_s) / (hybrid_total_bytes) + " ms/B");
disp("Max latency per image: " + max(hybridlatency.LATENCYMS) / ms_per_s + " s/image");
disp("Median latency per image: " + median(hybridlatency.LATENCYMS) / ms_per_s + " s/image");
disp("Mean image size: " + mean(hybridlatency.NBYTES) / KiB + " KiB");
disp("Median image size: " + median(hybridlatency.NBYTES) / KiB + "KiB")
disp("======");

data_faster = hybridlatency.LATENCYMS - datalatency.LATENCYMS;
data_faster_ids = data_faster > 0;

hybrid_faster = datalatency.LATENCYMS - hybridlatency.LATENCYMS;
hybrid_faster_ids = hybrid_faster > 0;

image_sizes_kib = datalatency.NBYTES ./ KiB;

figure();
hold on;
scatter(image_sizes_kib(hybrid_faster_ids), hybridlatency.LATENCYMS(hybrid_faster_ids), "o", "DisplayName", "Hybrid was faster");
scatter(image_sizes_kib(data_faster_ids), datalatency.LATENCYMS(data_faster_ids), "o", "DisplayName", "Data was faster");

legend show;


