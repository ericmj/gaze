import Reflux from "bower_components/reflux/dist/reflux";
import channelMixin from "./ChannelMixin";

const MAX_TICKS = 60;

export default Reflux.createStore({
  mixins: [channelMixin("charts")],

  init() {
    this.average = [];
    this.schedulers = [];
  },

  getInitialState() {
    return null;
    // TODO
  },

  onUpdate(data) {
    var sum = 0;
    var length = data.schedulers.length;

    data.schedulers.forEach((freq, i) => {
      sum += freq;

      if (!this.schedulers[i])
        this.schedulers[i] = [];

      pushFreq(this.schedulers[i], freq);
    });

    if (length == 0)
      var avg = 0;
    else
      var avg = sum / data.schedulers.length;

    pushFreq(this.average, avg);

    this.trigger({
      average: this.average,
      all: this.schedulers,
      max_ticks: MAX_TICKS
    });
  }
});

var pushFreq = (array, value) => {
  array.push(value);

  if (array.length > MAX_TICKS)
    array.shift();
}
