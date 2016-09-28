'use babel';

import LinterClccView from './linter-clcc-view';
import { CompositeDisposable } from 'atom';

export default {

  linterClccView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.linterClccView = new LinterClccView(state.linterClccViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.linterClccView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'linter-clcc:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.linterClccView.destroy();
  },

  serialize() {
    return {
      linterClccViewState: this.linterClccView.serialize()
    };
  },

  toggle() {
    console.log('LinterClcc was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
