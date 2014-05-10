import java.util.Map;

PShape world;

PVector camera;

int nmonths = 13;
// number of months in range (2012-11 to 2013-11).

float[] vals;
// list of bitcoin price per date.

float[] volumes;
// list of bitcoin trade volume per month.

ArrayList<HashMap<String, Float>> gox_array;
// number of bitcoins for 13 months (2012-11 to 2013-11) for every country.

ArrayList<HashMap<String, Float>> gox_cumulative;
// cumulative number of bitcoins for 13 months (2012-11 to 2013-11) for every country.

float[] gox_mins;
float[] gox_maxs;
// minimum and maximum bitcoin values by any country in i-th month.

int price_days = 0;
// price averages per day for one year (2012-11 to 2013-11).

int volume_months = 0;
// average bitcoin volume per month.

float plot_stretch_factor = 0.0;
// constant to have plot over whole width of the screen.

float plot_volume_stretch_factor = 0.0;
// constant to have plot over whole width of the screen.

float ploat_squash_factor = 2.0;
// constant to normalize plot amplitude.

float volume_squash_factor = 4.0;
// constant to normalize plot amplitude.

float zoom = 2.0;

HashMap<String, String> keyCountry = new HashMap<String, String>();
HashMap<String, Float> valueCountry = new HashMap<String, Float>();

int canvasWidth = 1800;
int canvasHeight = 1000;

int plot_offset = 0;
// y offset of plot.

int prev_mouse_month = -1;
// previous month

HashMap<String, Float> gox_previous;
// previous gox_data month for all countries.

float prev_min;
float prev_max;

//Integrator[] itg;
Integer[] itg;
// current integrator

Integer[] brightness_itg;
// brightness integrator

Integer[] hue_itg;
// hue integrator

HashMap<String, Integer> country_index = new HashMap<String, Integer>();
// index of country.

String[] month = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
// months

void setup() {
  size(1800, 1000);
  world = loadShape("map.svg");
  camera = new PVector(-width/4, -height/4);

  String lines[] = loadStrings("country-codes.txt");
  for (int i = 0 ; i < lines.length; i++) {
    String[] keyValue = split(lines[i], '\t');
    keyCountry.put(keyValue[0], keyValue[1]);
    country_index.put(keyValue[0], i);
  }

  itg = new Integer[country_index.size()];
  brightness_itg = new Integer[country_index.size()];

  price();
  trade_volume();
  gox_data();

  smooth();
  frameRate(15);
}

void price() {
  String lines[] = loadStrings("mtgox-price_parsed.csv");
  price_days = lines.length;
  plot_stretch_factor = float(price_days) / float(canvasWidth); 
  vals = new float[price_days];

  for (int i = 0 ; i < price_days; i++) {
    String[] kv = split(lines[i], ',');
    vals[i] = float(kv[1]) / ploat_squash_factor;
  }
}

void trade_volume() {
  String lines[] = loadStrings("gox_volume.tsv");
  volume_months = lines.length;
  plot_volume_stretch_factor = float(volume_months) / float(canvasWidth); 
  volumes = new float[volume_months];

  for (int i = 0 ; i < volume_months; i++) {
    String[] kv = split(lines[i], '\t');
    volumes[i] = float(kv[1]); // volume_squash_factor;
  }
}

void gox_data() {
  gox_array = new ArrayList<HashMap<String, Float>>();
  gox_cumulative = new ArrayList<HashMap<String, Float>>();

  String lines[] = loadStrings("gox_data.tsv");

  int j = 0; // month index (0 to nmonths)
  int prev_month = 11;
  float tmin = MAX_FLOAT;
  float tmax = MIN_FLOAT;

  gox_mins = new float[nmonths];
  gox_maxs = new float[nmonths];

  HashMap<String, Float> x = new HashMap<String, Float>();
  HashMap<String, Float> c = new HashMap<String, Float>();

  for (int i = 0 ; i < lines.length; i++) {
    String[] kv = split(lines[i], '\t');
    String country = kv[2];
    if (country.equals("HK")) {
      continue;
    }
    if (country.equals("JP")) {
      continue;
    }
    if (country.equals("PA")) {
      continue;
    }
    if (country.equals("XX")) {
      continue;
    }

    int current_month = int(kv[1]);
    float bitcoins = float(kv[3]);

    // find min/max coins per month
    if (current_month == prev_month) {
      x.put(country, bitcoins);

      if (bitcoins > tmax) {
        tmax = bitcoins;
      }
      if (bitcoins < tmin) {
        tmin = bitcoins;
      }
    }
    else {
      gox_array.add(x);
      x = new HashMap<String, Float>();

      gox_mins[j] = tmin;
      gox_maxs[j] = tmax;
      tmin = MAX_FLOAT;
      tmax = MIN_FLOAT;
      j++;
    }

    if (current_month != prev_month) {
      gox_cumulative.add(c);
      c = new HashMap<String, Float>();
    }

    if (j > 0 && gox_cumulative.get(j - 1).get(country) != null) {
      c.put(country, gox_cumulative.get(j - 1).get(country) + bitcoins);
    }
    else {
      c.put(country, bitcoins);
    }

    if (i == lines.length - 1) {
      gox_array.add(x);

      gox_cumulative.add(c);

      gox_mins[j] = tmin;
      gox_maxs[j] = tmax;
    }
    prev_month = current_month;
  }

  gox_previous = gox_array.get(0);
  // previous gox_data month for all countries.

  prev_min = gox_mins[0];
  prev_max = gox_maxs[0];

  for (Map.Entry me : keyCountry.entrySet()) {
    String cc = me.getKey().toString();

    int brightness = 144;
    int k = country_index.get(cc);
    float first_btc;
    if (gox_previous.get(cc) == null) {
      first_btc = 0;
    }
    else {
      first_btc = gox_previous.get(cc);
    }

    if (first_btc != 0) {
      first_btc = 255 - map(gox_previous.get(cc), prev_min, prev_max, 0, 255);
      brightness = 255;
    }
    itg[k] = int(first_btc);
    brightness_itg[k] = brightness;
  }
}

void draw() {
  bunka(mouseX, mouseY);
}

String[] f_keyArray(HashMap<String, Float> x) {
  String[] s = new String[x.size()];
  int i = 0;
  for (Map.Entry me : x.entrySet()) {
    s[i] = me.getKey().toString();
    i++;
  }

  return s;
}

void bunka(float bunka_x, float bunka_y) {
  volume_plot();
  price_plot();
  float bunka_r = 15.0F;
  bunka_y = vals[int(bunka_x * plot_stretch_factor)];
  float current_volume = volumes[int(bunka_x * plot_volume_stretch_factor)];

  pushMatrix();
  scale(1, -1);
  translate(0, -height);
  translate(0, 30);

  colorMode(RGB);
  fill(211, 54, 130);
  strokeWeight(0);
  ellipse(bunka_x, bunka_y + plot_offset, bunka_r, bunka_r);
  popMatrix();

  int top_offset = 550;
  int left_offset = 10;
  int bar_width = 13;

  fill(88, 110, 117);

  String btc_price = str(round(bunka_y * ploat_squash_factor));

  textAlign(LEFT);
  text("Price (USD):", left_offset, top_offset - 210);
  textAlign(RIGHT);
  text(btc_price, left_offset + 150, top_offset - 210);

  String btc_volume = str(round(current_volume));
  textAlign(LEFT);
  text("Volume (BTC):", left_offset, top_offset - 190);
  textAlign(RIGHT);
  text(btc_volume, left_offset + 150, top_offset - 190);

  int mouse_month = int(mouseX * nmonths / float(canvasWidth));
  HashMap<String, Float> x = gox_array.get(mouse_month);
  String[] cc_sorted = f_keyArray(x);
  String cc_min = "MIN [" + cc_sorted[0] + "]: " + x.get(cc_sorted[0]);
  String cc_max = "MAX [" + cc_sorted[x.size() - 1] + "]: " + str(round(x.get(cc_sorted[x.size() - 1])));

  // Top delta countries (+)
  String[] ccs = {"US", "AU", "GB", "PL", "NL"};
  top_comulative_plus(top_offset, ccs);
  // Top delta countries (-)
  String[] ccd = {"RU", "UA", "VN", "RO", "CA"};
  top_comulative(top_offset + 130, ccd);
}

void top_comulative(int top_offset, String[] ccs) {
  int mouse_month = int(mouseX * nmonths / float(canvasWidth));
  HashMap<String, Float> a = gox_array.get(mouse_month);
  HashMap<String, Float> x = gox_cumulative.get(mouse_month);
  String[] cc_sorted = f_keyArray(x);

  int left_offset = 10;
  int bar_height = 13;

  int i = 0;

  float bar_compact_factor = 1777.7;

  textAlign(LEFT);
  text("Top sellers", left_offset, top_offset - 20);
  text("delta", left_offset + 110, top_offset - 20);
  text("cummulative", left_offset + 160, top_offset - 20);
  line(left_offset, top_offset - 17, left_offset + 300, top_offset - 17);

  for (String cc : ccs) {
    float bar_width_delta = 0.0;
    if (mouse_month > 0) {
      bar_width_delta = a.get(cc);
    }
    String bar_width_d = str(round(bar_width_delta));

    float bar_width = x.get(cc);
    String btc_round = str(round(bar_width));

    int delta_fill_r = 255;
    int delta_fill_g = 0;
    int delta_fill_b = 0;

    float correct_bar = 0.0;

    if (bar_width_delta > 0) {
      bar_width = abs((bar_width - bar_width_delta) / bar_compact_factor);
      correct_bar = abs(bar_width_delta / bar_compact_factor);
      delta_fill_r = 0;
      delta_fill_g = 255;
      delta_fill_b = 0;
    }
    else {
      bar_width = abs(bar_width / bar_compact_factor);
    }

    bar_width_delta = abs(bar_width_delta / bar_compact_factor);

    strokeWeight(0.1);

    fill(88, 110, 117);
    textAlign(LEFT);
    text(keyCountry.get(cc), left_offset, top_offset + i * 20);
    textAlign(RIGHT);
    text(btc_round, left_offset + 150, top_offset + i * 20);

    fill(255);
    rect(left_offset + 160, top_offset + i * 20 - bar_height + 2, bar_width - correct_bar, bar_height);

    fill(delta_fill_r, delta_fill_g, delta_fill_b);
    rect(left_offset + 160 + bar_width - bar_width_delta, top_offset + i * 20 - bar_height + 6, bar_width_delta, bar_height - 8);

    fill(88, 110, 117);
    textAlign(LEFT);
    text(bar_width_d, left_offset + 170 + bar_width, top_offset + i * 20);
    i++;
  }
}

void top_comulative_plus(int top_offset, String[] ccs) {
  int mouse_month = int(mouseX * nmonths / float(canvasWidth));
  HashMap<String, Float> a = gox_array.get(mouse_month);
  HashMap<String, Float> x = gox_cumulative.get(mouse_month);
  String[] cc_sorted = f_keyArray(x);

  int left_offset = 10;
  int bar_height = 13;

  int i = 0;

  float bar_compact_factor = 1777.7;

  textAlign(LEFT);
  text("Top buyers:", left_offset, top_offset - 20);
  text("delta", left_offset + 110, top_offset - 20);
  text("cummulative", left_offset + 160, top_offset - 20);
  line(left_offset, top_offset - 17, left_offset + 300, top_offset - 17);

  for (String cc : ccs) {
    float bar_width_delta = 0.0;
    if (mouse_month > 0) {
      bar_width_delta = a.get(cc);
    }
    String bar_width_d = str(round(bar_width_delta));

    float bar_width = x.get(cc);
    String btc_round = str(round(bar_width));

    int delta_fill_r = 255;
    int delta_fill_g = 0;
    int delta_fill_b = 0;

    float correct_bar = 0.0;

    if (bar_width_delta > 0) {
      bar_width = abs((bar_width) / bar_compact_factor);
      delta_fill_r = 0;
      delta_fill_g = 255;
      delta_fill_b = 0;
    }
    else {
      bar_width = abs((bar_width - bar_width_delta) / bar_compact_factor);
      correct_bar = abs(bar_width_delta / bar_compact_factor);
    }

    bar_width_delta = abs(bar_width_delta / bar_compact_factor);

    fill(88, 110, 117);
    textAlign(LEFT);
    text(keyCountry.get(cc), left_offset, top_offset + i * 20);
    textAlign(RIGHT);
    text(btc_round, left_offset + 150, top_offset + i * 20);

    fill(255);
    rect(left_offset + 160, top_offset + i * 20 - bar_height + 2, bar_width - correct_bar, bar_height);

    fill(delta_fill_r, delta_fill_g, delta_fill_b);
    rect(left_offset + 160 + bar_width - bar_width_delta, top_offset + i * 20 - bar_height + 6, bar_width_delta, bar_height - 8);

    fill(88, 110, 117);
    textAlign(LEFT);
    text(bar_width_d, left_offset + 170 + bar_width, top_offset + i * 20);
    i++;
  }
}

void price_plot() {
  pushMatrix();
  scale(1, -1);
  translate(0, -height);
  translate(0, 30);
  // Draw lines connecting all points
  colorMode(RGB);
  stroke(101, 122, 129);
  strokeWeight(4.0);
  for (int i = 0; i < vals.length - 1; i++) {
    line(i / plot_stretch_factor, vals[i] + plot_offset, (i + 1) / plot_stretch_factor, vals[i+1] + plot_offset);
  }
  popMatrix();
}

void volume_plot() {
  draw_map();
  int volume_width = canvasWidth / volume_months - 7;
  pushMatrix();
  scale(1, -1);
  translate(0, -height);
  translate(0, 30);
  colorMode(RGB);
  fill(238, 232, 213);
  colorMode(HSB);
  stroke(0);
  strokeWeight(1.0);
  for (int i = 0; i < volumes.length; i++) {
    colorMode(RGB);
    fill(238, 232, 213);
    rect(i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/2, 0, volume_width, volumes[i] / 5000);
    if (i % 3 == 0) {
      line(
        i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/2,
        -5,
        i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/6 + volume_width * 3,
        -5
      );
      line(
        (i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/2 + i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/6 + volume_width * 3) / 2,
        -5,
        (i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/2 + i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/6 + volume_width * 3) / 2,
        -15
      );
      fill(88, 110, 117);
      textAlign(CENTER);
      pushMatrix();
      scale(1, -1);
      text(
        month[((i/3 % 12) + 12 + 10) % 12],
        (i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/2 + i / plot_volume_stretch_factor + 1 / plot_volume_stretch_factor / 2 - volume_width/6 + volume_width * 3) / 2,
        25
      );
      popMatrix();
    }
  }
  popMatrix();
}

void legend(HashMap<String, Float> gox_current, float min, float max) {

  int top_offset = 580;
  int left_offset = 10;

  String[] ccs = {"US", "AU", "GB", "PL", "NL", "RU", "UA", "VN", "RO", "CA"};
  HashMap<String, Float> f = new HashMap<String, Float>();

  for (int i=0; i<ccs.length; i++) {
    String cc = ccs[i];
    f.put(cc, gox_current.get(cc));
  }

  float[] top_btc = new float[f.size()];
  int i = 0;
  for (Map.Entry me : f.entrySet()) {
    String cc = me.getKey().toString();
    float tmp_btc = f.get(cc);
    if (tmp_btc > max) {
      tmp_btc = max;
    }
    top_btc[i] = tmp_btc;
    i++;
  }

  top_btc = sort(top_btc);

  String[] cc_sorted = f_keyArray(gox_current);
  String current_btc;

  float c1 = min;
  float r1 = map(min, min, max, 0, 100);

  float c2 = (top_btc[2] + top_btc[3]) / 2;
  float r2 = map(c2, min, max, 0, 100);

  float c3 = (top_btc[4] + top_btc[5]) / 2;
  float r3 = map(c3, min, max, 0, 100);

  float c4 = (top_btc[6] + top_btc[7]) / 2;
  float r4 = map(c4, min, max, 0, 100);

  float c5 = max;
  float r5 = map(max, min, max, 0, 100);

  textAlign(RIGHT);

  fill(r5 * 0.85, 255 * 0.85, 255 + 208);
  current_btc = str(round(c5));
  rect(left_offset, top_offset - 200, 10, 10);
  fill(88, 110, 117);
  text(current_btc, left_offset + 150, top_offset - 190);

  fill(r4 * 0.85, 255 * 0.85, 255 + 208);
  current_btc = str(round(c4));
  rect(left_offset, top_offset - 185, 10, 10);
  fill(88, 110, 117);
  text(current_btc, left_offset + 150, top_offset - 175);

  fill(r3 * 0.85, 255 * 0.85, 255 + 208);
  current_btc = str(round(c3));
  rect(left_offset, top_offset - 170, 10, 10);
  fill(88, 110, 117);
  text(current_btc, left_offset + 150, top_offset - 160);

  fill(r2 * 0.85, 255 * 0.85, 255 + 208);
  current_btc = str(round(c2));
  rect(left_offset, top_offset - 155, 10, 10);
  fill(88, 110, 117);
  text(current_btc, left_offset + 150, top_offset - 145);

  fill(int(r1 * 0.85), int(255 * 0.85), 255 + 208);
  current_btc = str(round(c1));
  rect(left_offset, top_offset - 140, 10, 10);
  fill(88, 110, 117);
  text(current_btc, left_offset + 150, top_offset - 130);
}

void draw_map() {
  int mouse_month = int(mouseX * nmonths / float(canvasWidth));
  // index [from 0 to nmonths] of gox_array.

  HashMap<String, Float> gox_current = gox_array.get(mouse_month);
  // current gox_data month for all countries.

  float[] cc_sorted = new float[gox_current.size()];
  int i = 0;
  for (Map.Entry me : gox_current.entrySet()) {
    cc_sorted[i] = float(me.getValue().toString());
    i++;
  }

  cc_sorted = sort(cc_sorted);

  colorMode(RGB);
  background(238, 238, 218);

  colorMode(HSB);

  float curr_min = cc_sorted[0 + 7];
  float curr_max = cc_sorted[cc_sorted.length - 1 - 7];

  legend(gox_current, cc_sorted[0], cc_sorted[cc_sorted.length - 1]);
  // draw legend

  scale(zoom);
  colorMode(HSB);

  for (Map.Entry me : keyCountry.entrySet()) {
    String cc = me.getKey().toString();
    PShape country = world.getChild(cc);
    if (country == null) {
      continue;
    }
    country.disableStyle();

    int brightness = 0;

    float current_btc;
    if (gox_current.get(cc) == null) {
      current_btc = 0;
    }
    else {
      current_btc = gox_current.get(cc);
    }

    // ignore small changes
    if (abs(current_btc) < 500) {
      current_btc = 0;
    }

    // amplify values
    if (current_btc < 0) {
      current_btc = current_btc;
    }
    else if (current_btc > 0) {
      current_btc = current_btc;
    }

    if (current_btc != 0) {
      if (current_btc > curr_max) {
        current_btc = curr_max;
      }
      current_btc = map(current_btc, curr_min, curr_max, 0, 100);
      brightness = 255;
    }

    float prev_btc;
    if (gox_previous.get(cc) == null) {
      prev_btc = 0;
    }
    else {
      prev_btc = gox_previous.get(cc);
    }

    if (prev_btc != 0) {
      prev_btc = map(gox_previous.get(cc), prev_min, prev_max, 0, 100);
    }

    int k = country_index.get(cc);
    itg[k] = int(current_btc);

    brightness_itg[k] = brightness;

    fill(max(0, int(itg[k] * 0.85)), max(0, int(brightness_itg[k] * 0.85)), max(0, int(brightness_itg[k] + 208)));

    noStroke();
    shape(country, 0, 0, country.width, country.height);
  }

  gox_previous = gox_current;
  prev_min = curr_min;
  prev_max = curr_max;

  scale(0.5);
}

